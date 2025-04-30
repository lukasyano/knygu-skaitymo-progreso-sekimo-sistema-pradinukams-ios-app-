import Combine
import FirebaseAuth
import Foundation

public enum AuthUIError: LocalizedError {
    case message(String)

    public var errorDescription: String? {
        switch self {
        case let .message(message): return message
        }
    }
}

public protocol FirebaseAuthService {
    func createUser(email: String, password: String) -> AnyPublisher<User, AuthUIError>
    func signIn(email: String, password: String) -> AnyPublisher<User, AuthUIError>
    func signOut() throws
    func getCurrentUser() -> User?
}

public final class DefaultFirebaseAuthService: FirebaseAuthService {
    public init() {}

    public func createUser(email: String, password: String) -> AnyPublisher<User, AuthUIError> {
        Future { promise in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    promise(.failure(Self.mapFirebaseError(error)))
                } else if let user = result?.user {
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func signIn(email: String, password: String) -> AnyPublisher<User, AuthUIError> {
        Future { promise in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    promise(.failure(Self.mapFirebaseError(error)))
                } else if let user = result?.user {
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func signOut() throws {
        try Auth.auth().signOut()
    }

    public func getCurrentUser() -> User? {
        Auth.auth().currentUser
    }
}

extension DefaultFirebaseAuthService {
    private static func mapFirebaseError(_ error: Error) -> AuthUIError {
        guard
            let error = error as NSError?,
            let code = AuthErrorCode(rawValue: error.code)
        else {
            return .message("Įvyko nežinoma klaida!")
        }

        switch code {
        case .invalidEmail:
            return .message("Neteisingas el. pašto adresas.")
        case .emailAlreadyInUse:
            return .message("Šis el. paštas jau registruotas! Prašome registuotis su kitais el. paštu.")
        case .weakPassword:
            return .message("Naudokite stipresnį slaptažodį (min. 6 simboliai).")
        case .wrongPassword:
            return .message("Neteisingas slaptažodis.")
        case .userNotFound:
            return .message("Toks naudotojas nerastas.")
        case .networkError:
            return .message("Ryšio klaida. Patikrinkite internetą.")
        default:
            return .message(error.localizedDescription)
        }
    }
}
