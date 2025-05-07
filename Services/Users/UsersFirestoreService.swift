import Combine
import FirebaseFirestore
import Foundation

protocol UsersFirestoreService {
    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error>
    func getUserEntity(userID: String) -> AnyPublisher<UserEntity, Error>
}

class DefaultUsersFirestoreService: UsersFirestoreService {
    private let fireStoreReference = Firestore.firestore()

    func getUserEntity(userID: String) -> AnyPublisher<UserEntity, Error> {
        Future<UserEntity, Error> { promise in
            self.fireStoreReference.collection("users").document(userID).getDocument { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }

                guard let document = snapshot, document.exists else {
                    promise(.failure(NSError(domain: "Toks vartotojas nerastas Firestore", code: 404)))
                    return
                }

                guard let data = document.data() else {
                    promise(.failure(NSError(domain: "InvalidUserData", code: 400)))
                    return
                }

                let user = UserEntity(
                    id: document.documentID,
                    email: data["email"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    role: Role(rawValue: data["role"] as? String ?? "") ?? .unknown,
                    parentID: data["parentId"] as? String,
                    childrensID: data["childrensID"] as? [String] ?? [],
                    points: data["totalPoints"] as? Int ?? 0
                )

                promise(.success(user))
            }
        }
        .eraseToAnyPublisher()
    }

    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        let userRef = fireStoreReference.collection("users").document(user.id)

        // 1) Build the top-level user payload
        var payload: [String: Any] = [
            "email": user.email,
            "name": user.name,
            "role": user.role.rawValue
        ]

        switch user.role {
        case .parent:
            // only parents get a 'children' array
            payload["children"] = user.childrensID

        case .child:
            // only children get 'parentId' + 'totalPoints'
            if let pid = user.parentID {
                payload["parentId"] = pid
                payload["totalPoints"] = user.totalPoints
            }

        case .unknown:
            break
        }

        // 2) Wrap the top-level setData in a Future
        let userWrite = Future<Void, Error> { promise in
            userRef.setData(payload, merge: true) { err in
                err.map { promise(.failure($0)) } ?? promise(.success(()))
            }
        }
        .eraseToAnyPublisher()

        // 3) If this is a child, also write each Progress into /progress/{bookId}
        let progressWrites: AnyPublisher<Void, Error>
        if user.role == .child {
            // Map each Progress → a Future write (skipping any entry without a linked book)
            let writes = user.progressEntries.compactMap { entry -> AnyPublisher<Void, Error>? in
                guard let book = entry.book else { return nil }
                let pData: [String: Any] = [
                    "pagesRead": entry.pagesRead,
                    "totalPages": entry.totalPages,
                    "finished": entry.finished,
                    "pointsEarned": entry.pointsEarned
                ]
                let pRef = userRef
                    .collection("progress")
                    .document(book.id)

                return Combine.Future<Void, Error> { promise in
                    pRef.setData(pData, merge: true) { err in
                        err.map { promise(.failure($0)) }
                            ?? promise(.success(()))
                    }
                }
                .eraseToAnyPublisher()
            }

            // Merge them all and wait for completion
            progressWrites = Publishers
                .MergeMany(writes)
                .collect()
                .mapToVoid() // wait for _all_ of them

        } else {
            progressWrites = .just(())
        }

        // 4) Chain top-level write → progress writes
        return userWrite
            .flatMap { progressWrites }
            .eraseToAnyPublisher()
    }
}
