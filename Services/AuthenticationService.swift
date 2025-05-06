import Combine
import FirebaseAuth
import Foundation

enum UserError: LocalizedError {
    case message(String)

    public var errorDescription: String? {
        switch self {
        case let .message(message): return message
        }
    }
}

protocol AuthenticationService {
    func createUser(email: String, password: String) -> AnyPublisher<User, UserError>
    func signIn(email: String, password: String) -> AnyPublisher<User, UserError>
    func signOut() throws
    func getUserID() -> String?
}

final class DefaultAuthenticationService: AuthenticationService {
    private let instance = Auth.auth()

    func createUser(email: String, password: String) -> AnyPublisher<User, UserError> {
        Future { [weak instance] promise in
            instance?.createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    promise(.failure(Self.mapFirebaseError(error)))
                } else if let user = result?.user {
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func signIn(email: String, password: String) -> AnyPublisher<User, UserError> {
        Future { [weak instance] promise in
            instance?.signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    promise(.failure(Self.mapFirebaseError(error)))
                } else if let user = result?.user {
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func signOut() throws {
        try instance.signOut()
    }

    func getUserID() -> String? {
        let userID = instance.currentUser?.uid
        print(String("UserID: \(userID ?? "Nera userID)")"))
        return userID
    }
}

extension DefaultAuthenticationService {
    private static func mapFirebaseError(_ error: Error) -> UserError {
        guard
            let error = error as NSError?,
            let code = AuthErrorCode(rawValue: error.code)
        else {
            return .message("Įvyko nežinoma klaida! Bandyk dar kartą.")
        }

        switch code {
        case .invalidEmail:
            return .message("Neteisingas el. pašto adresas.")
        case .emailAlreadyInUse:
            return .message("Šis el. paštas jau registruotas!")
        case .weakPassword:
            return .message("Naudokite stipresnį slaptažodį (min. 6 simboliai).")
        case .wrongPassword, .invalidCredential:
            return .message("Neteisingi duomenys.")
        case .userNotFound:
            return .message("Toks naudotojas nerastas.")
        case .networkError:
            return .message("Ryšio klaida. Patikrinkite internetą.")
        default:
            return .message("Įvyko nežinoma klaida! Bandyk dar kartą.")
        }
    }
}
