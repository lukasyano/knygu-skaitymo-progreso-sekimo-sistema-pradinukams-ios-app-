import Combine
import FirebaseFirestore
import Foundation

public protocol UserProfileService {
    func saveUserProfile(userID: String, email: String, role: Role) -> AnyPublisher<Void, Error>
    func getUserRole(userID: String) -> AnyPublisher<String?, Error>
}

public class DefaultUserProfileService: UserProfileService {
    private let fireStoreReference = Firestore.firestore()

    public init() {}

    public func saveUserProfile(userID: String, email: String, role: Role) -> AnyPublisher<Void, Error> {
        Future { promise in
            let userReference = self.fireStoreReference.collection("users").document(userID)
            userReference.setData([
                "email": email,
                "role": role.rawValue,
            ], merge: true) { [weak self] error in

                if let error = error {
                    print("❌ Failed to save user profile: \(error.localizedDescription)")
                    promise(.failure(error))
                } else {
                    print("✅ User profile saved successfully")
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }

    public func getUserRole(userID: String) -> AnyPublisher<String?, Error> {
        Future { promise in
            let userReference = self.fireStoreReference.collection("users").document(userID)
            userReference.getDocument { snapshot, error in
                if let error = error {
                    print("❌ Failed to fetch user role: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }

                let role = snapshot?.data()?["role"] as? String
                promise(.success(role))
            }
        }.eraseToAnyPublisher()
    }
}
