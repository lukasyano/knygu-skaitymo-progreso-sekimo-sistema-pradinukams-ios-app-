import Combine
import FirebaseFirestore
import Foundation

public protocol UserService {
    func saveUserProfile(userID: String, email: String, role: Role) -> AnyPublisher<Void, Error>
    func getUserRole(userID: String) -> AnyPublisher<Role?, Never>
}

public class DefaultUserProfileService: UserService {
    private let fireStoreReference = Firestore.firestore()

    public init() {}

    public func saveUserProfile(userID: String, email: String, role: Role) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            self?.fireStoreReference.collection("users")
                .document(userID)
                .setData([
                    "email": email,
                    "role": role.rawValue
                ], merge: true) { error in
                    if let error = error {
                        print("❌ Failed to save user profile: \(error.localizedDescription)")
                        promise(.failure(error))
                    } else {
                        print("✅ User profile saved successfully")
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    public func getUserRole(userID: String) -> AnyPublisher<Role?, Never> {
        Future { promise in
            let userReference = self.fireStoreReference.collection("users").document(userID)
            userReference.getDocument { snapshot, error in
                if let error = error {
                    promise(.success(nil))
                    return
                }

                if let roleString = snapshot?.data()?["role"] as? String {
                    let role = Role(rawValue: roleString)
                    promise(.success(role))
                } else {
                    promise(.success(nil))
                }
            }
        }.eraseToAnyPublisher()
    }
}
