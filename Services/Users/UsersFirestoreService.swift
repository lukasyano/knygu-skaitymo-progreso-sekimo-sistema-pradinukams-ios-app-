import Combine
import FirebaseFirestore
import Foundation

protocol UsersFirestoreService {
    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error>
    func getUserRole(userID: String) -> AnyPublisher<Role?, Never>
    // func linkChildToParent(childID: String, parentID: String) -> AnyPublisher<Void, Error>
    // func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], Error>
    // func getAllParents() -> AnyPublisher<[UserEntity], Error>
}

class DefaultUsersFirestoreService: UsersFirestoreService {
    private let fireStoreReference = Firestore.firestore()

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
                err.map { promise(.failure($0)) }
                    ?? promise(.success(()))
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

//    func linkChildToParent(childID: String, parentID: String) -> AnyPublisher<Void, Error> {
//        Future { [weak self] promise in
//            self?.fireStoreReference.collection("users").document(parentID)
//                .updateData([
//                    "childrensID": FieldValue.arrayUnion([childID])
//                ]) { error in
//                    if let error = error {
//                        promise(.failure(error))
//                    } else {
//                        promise(.success(()))
//                    }
//                }
//        }
//        .eraseToAnyPublisher()
//    }

//    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], Error> {
//        Future { [weak self] promise in
//            self?.fireStoreReference.collection("users").document(parentID).getDocument {
//                snapshot, error in
//                if let error = error {
//                    promise(.failure(error))
//                    return
//                }
//                guard let childrenIDs = snapshot?.data()?["childrensID"] as? [String],
//                      !childrenIDs.isEmpty else {
//                    promise(.success([]))
//                    return
//                }
//                self?.fireStoreReference.collection("users")
//                    .whereField(FieldPath.documentID(), in: childrenIDs)
//                    .getDocuments { snapshot, error in
//                        if let error = error { promise(.failure(error))
//                            return
//                        }
//
//                        let users = snapshot?.documents.compactMap { doc -> UserEntity? in
//                            let data = doc.data()
//
//                            guard
//                                let roleRaw = data["role"] as? String,
//                                let role = Role(rawValue: roleRaw)
//                            else {
//                                return nil
//                            }
//
//                            return UserEntity(
//                                id: doc.documentID,
//                                email: data["email"] as? String ?? "",
//                                name: data["name"] as? String ?? "",
//                                role: role,
//                                childrensID: [],
//                                points: data["points"] as? Int ?? 0
//                            )
//                        } ?? []
//
//                        promise(.success(users))
//                    }
//            }
//        }
//        .eraseToAnyPublisher()
//    }

    func getUserRole(userID: String) -> AnyPublisher<Role?, Never> {
        Future { [weak self] promise in
            self?.fireStoreReference.collection("users").document(userID).getDocument { snapshot, _ in
                if let roleString = snapshot?.data()?["role"] as? String {
                    promise(.success(Role(rawValue: roleString)))
                } else {
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getAllParents() -> AnyPublisher<[UserEntity], Error> {
        Future { [weak self] promise in
            self?.fireStoreReference.collection("users")
                .whereField("role", isEqualTo: Role.parent.rawValue)
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    let parents = snapshot?.documents.compactMap { doc -> UserEntity? in
                        let data = doc.data()
                        guard let email = data["email"] as? String else { return nil }
                        guard let name = data["name"] as? String else { return nil }
                        return UserEntity(
                            id: doc.documentID,
                            email: email,
                            name: name,
                            role: .parent,
                            parentID: nil,
                            childrensID: data["childrensID"] as? [String] ?? [],
                            points: data["points"] as? Int ?? 0
                        )
                    } ?? []
                    promise(.success(parents))
                }
        }
        .eraseToAnyPublisher()
    }
}
