import Combine
import FirebaseAuth
import Resolver

public protocol AuthenticationRepository {
    func signUp(email: String, password: String, role: Role) -> AnyPublisher<User, AuthUIError>
    func signIn(email: String, password: String, remember: Bool) -> AnyPublisher<User, AuthUIError>
    func getRememberedEmail() -> AnyPublisher<String, Never>
    func getCurrentUser() -> User?
    func signOut() throws
    func savedEmail() -> String?
    func shouldRememberUser() -> Bool
}

public class DefaultAuthenticationRepository {
    private let firebaseAuthService: FirebaseAuthService
    private var credentialsStore: CredentialsStore
    private let userProfileService: UserProfileService

    public init(
        firebaseAuthService: FirebaseAuthService = Resolver.resolve(),
        credentialsStore: CredentialsStore = Resolver.resolve(),
        userProfileService: UserProfileService = Resolver.resolve()
    ) {
        self.firebaseAuthService = firebaseAuthService
        self.credentialsStore = credentialsStore
        self.userProfileService = userProfileService
    }
}

extension DefaultAuthenticationRepository: AuthenticationRepository {
    public func signUp(email: String, password: String, role: Role) -> AnyPublisher<User, AuthUIError> {
        firebaseAuthService.createUser(email: email, password: password)
            .flatMap { [weak self] user -> AnyPublisher<User, AuthUIError> in
                guard let self = self else {
                    return Fail(error: .message("Unknown error")).eraseToAnyPublisher()
                }

                return self.userProfileService
                    .saveUserProfile(userID: user.uid, email: user.email ?? email, role: role)
                    .map { user }
                    .mapError { AuthUIError.message($0.localizedDescription) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func getRememberedEmail() -> AnyPublisher<String, Never> {
        let email = credentialsStore.savedEmail ?? ""
        return Just(email).eraseToAnyPublisher()
    }

    public func signIn(email: String, password: String, remember: Bool) -> AnyPublisher<User, AuthUIError> {
        firebaseAuthService.signIn(email: email, password: password)
            .handleEvents(receiveOutput: { [weak self] (_: User) in
                if remember {
                    self?.credentialsStore.savedEmail = email
                    self?.credentialsStore.rememberUser = true
                } else {
                    self?.credentialsStore.clear()
                }
            })
            .eraseToAnyPublisher()
    }

    public func getCurrentUser() -> User? {
        firebaseAuthService.getCurrentUser()
    }

    public func signOut() throws {
        try firebaseAuthService.signOut()
        credentialsStore.clear()
    }

    public func savedEmail() -> String? {
        credentialsStore.savedEmail
    }

    public func shouldRememberUser() -> Bool {
        credentialsStore.rememberUser
    }
}
