import Combine
import FirebaseAuth
import Resolver

protocol AuthenticationRepository {
    func signUp(email: String, password: String, role: Role) -> AnyPublisher<User, AuthUIError>
    func signIn(email: String, password: String, remember: Bool) -> AnyPublisher<User, AuthUIError>
    func getRememberedEmail() -> AnyPublisher<String, Never>
    func getCurrentUser() -> User?
    func signOut() throws
    func savedEmail() -> String?
    func shouldRememberUser() -> Bool
}

class DefaultAuthenticationRepository {
    private let firebaseAuthService: AuthenticationService
    private var credentialsStore: CredentialsStore
    private let userProfileService: UserService

    init(
        firebaseAuthService: AuthenticationService = Resolver.resolve(),
        credentialsStore: CredentialsStore = Resolver.resolve(),
        userProfileService: UserService = Resolver.resolve()
    ) {
        self.firebaseAuthService = firebaseAuthService
        self.credentialsStore = credentialsStore
        self.userProfileService = userProfileService
    }
}

extension DefaultAuthenticationRepository: AuthenticationRepository {
    func signUp(email: String, password: String, role: Role) -> AnyPublisher<User, AuthUIError> {
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

    func getRememberedEmail() -> AnyPublisher<String, Never> {
        let email = credentialsStore.savedEmail ?? ""
        return Just(email).eraseToAnyPublisher()
    }

    func signIn(email: String, password: String, remember: Bool) -> AnyPublisher<User, AuthUIError> {
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

    func getCurrentUser() -> User? {
        firebaseAuthService.getCurrentUser()
    }

    func signOut() throws {
        try firebaseAuthService.signOut()
        credentialsStore.clear()
    }

    func savedEmail() -> String? {
        credentialsStore.savedEmail
    }

    func shouldRememberUser() -> Bool {
        credentialsStore.rememberUser
    }
}
