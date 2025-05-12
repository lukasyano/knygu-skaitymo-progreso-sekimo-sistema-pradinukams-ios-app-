import Combine
import FirebaseFirestore
import Foundation

protocol UsersFirestoreService {
    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error>
    func updateParentWithChild(parentID: String, childID: String) -> AnyPublisher<Void, Error>
    func getUserEntity(userID: String) -> AnyPublisher<UserEntity, Error>
    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], Error>
    func getProgressData(userID: String) -> AnyPublisher<[ProgressData], Error>
}

final class DefaultUsersFirestoreService: UsersFirestoreService {
    private let fireStoreReference = Firestore.firestore()

    func getProgressData(userID: String) -> AnyPublisher<[ProgressData], Error> {
        guard !userID.isEmpty else {
            return Fail(error: NSError(domain: "InvalidUserID", code: 400, userInfo: nil))
                .eraseToAnyPublisher()
        }

        let progressRef = fireStoreReference
            .collection("users")
            .document(userID)
            .collection("progress")

        return Deferred {
            let subject = PassthroughSubject<[ProgressData], Error>()
            var listener: ListenerRegistration?

            listener = progressRef.addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    subject.send(completion: .failure(NSError(domain: "UnknownError", code: 500, userInfo: nil)))
                    return
                }

                let progressData = snapshot.documents.map { document -> ProgressData in
                    let data = document.data()
                    return ProgressData(
                        bookId: document.documentID,
                        pagesRead: data["pagesRead"] as? Int ?? 0,
                        totalPages: data["totalPages"] as? Int ?? 0,
                        finished: data["finished"] as? Bool ?? false,
                        pointsEarned: data["pointsEarned"] as? Int ?? 0
                    )
                }
                subject.send(progressData)
            }

            return subject.handleEvents(receiveCancel: {
                listener?.remove()
            })
        }
        .eraseToAnyPublisher()
    }

    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], Error> {
        Future<QuerySnapshot, Error> { promise in
            self.fireStoreReference.collection("users")
                .whereField("parentId", isEqualTo: parentID)
                .getDocuments { snapshot, error in
                    error.map { promise(.failure($0)) } ?? promise(.success(snapshot!))
                }
        }
        .flatMap { snapshot in
            Publishers.MergeMany(
                snapshot.documents.map { self.getUserEntity(document: $0) }
            )
            .collect()
        }
        .eraseToAnyPublisher()
    }

    private func getUserEntity(document: QueryDocumentSnapshot) -> AnyPublisher<UserEntity, Error> {
        Future<UserEntity, Error> { promise in
            self.fetchCompleteUserData(document: document) { result in
                switch result {
                case let .success(user):
                    promise(.success(user))
                case let .failure(error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getUserEntity(userID: String) -> AnyPublisher<UserEntity, Error> {
        Future<UserEntity, Error> { promise in
            let userRef = self.fireStoreReference.collection("users").document(userID)

            userRef.getDocument { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }

                guard let document = snapshot, document.exists else {
                    promise(.failure(NSError(domain: "UserNotFound", code: 404)))
                    return
                }

                self.fetchCompleteUserData(document: document) { result in
                    switch result {
                    case let .success(user):
                        promise(.success(user))
                    case let .failure(error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func fetchCompleteUserData(
        document: DocumentSnapshot,
        completion: @escaping (Result<UserEntity, Error>) -> Void
    ) {
        guard let data = document.data() else {
            completion(.failure(NSError(domain: "InvalidUserData", code: 400)))
            return
        }

        let baseUser = UserEntity(
            id: document.documentID,
            email: data["email"] as? String ?? "",
            name: data["name"] as? String ?? "",
            role: Role(rawValue: data["role"] as? String ?? ""),
            parentID: data["parentId"] as? String,
            childrensID: data["children"] as? [String] ?? [],
            totalPoints: data["totalPoints"] as? Int ?? 0
        )

        fetchProgressData(userRef: document.reference) { progressData in
            var user = baseUser
            user.progressData = progressData
            completion(.success(user))
        }
    }

    private func fetchProgressData(userRef: DocumentReference, completion: @escaping ([ProgressData]) -> Void) {
        userRef.collection("progress").getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            let progressData = documents.compactMap { doc -> ProgressData? in
                let data = doc.data()
                return ProgressData(
                    bookId: doc.documentID,
                    pagesRead: data["pagesRead"] as? Int ?? 0,
                    totalPages: data["totalPages"] as? Int ?? 0,
                    finished: data["finished"] as? Bool ?? false,
                    pointsEarned: data["pointsEarned"] as? Int ?? 0
                )
            }

            completion(progressData)
        }
    }

    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        let userRef = fireStoreReference.collection("users").document(user.id)

        var payload: [String: Any] = [
            "email": user.email,
            "name": user.name,
            "role": user.role.rawValue,
            "children": user.children.map { $0.id }
        ]

        switch user.role {
        case .parent:
            payload["children"] = user.childrensID

        case .child:
            payload["parentId"] = user.parentID
            payload["totalPoints"] = user.totalPoints

        case .unknown: break
        }

        return Future<Void, Error> { promise in
            userRef.setData(payload, merge: true) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    self.saveProgressData(user: user, userRef: userRef) { progressError in
                        if let progressError = progressError {
                            promise(.failure(progressError))
                        } else {
                            promise(.success(()))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func saveProgressData(
        user: UserEntity,
        userRef: DocumentReference,
        completion: @escaping (Error?) -> Void
    ) {
        guard user.role == .child else {
            completion(nil)
            return
        }

        let batch = fireStoreReference.batch()
        let progressCollection = userRef.collection("progress")

        for entry in user.progressData {
            let docRef = progressCollection.document(entry.bookId)
            let data: [String: Any] = [
                "pagesRead": entry.pagesRead,
                "totalPages": entry.totalPages,
                "finished": entry.finished,
                "pointsEarned": entry.pointsEarned
            ]
            batch.setData(data, forDocument: docRef)
        }

        batch.commit { error in
            completion(error)
        }
    }

    func updateParentWithChild(parentID: String, childID: String) -> AnyPublisher<Void, Error> {
        let parentRef = fireStoreReference.collection("users").document(parentID)

        return Future<Void, Error> { promise in
            parentRef.updateData([
                "children": FieldValue.arrayUnion([childID])
            ]) { error in
                error.map { promise(.failure($0)) } ?? promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}
