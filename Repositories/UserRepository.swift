import Combine
import Resolver
import SwiftData

protocol UserRepository {
    func createUser(name: String, email: String, password: String, role: Role) -> AnyPublisher<String, UserError>
    func logIn(email: String, password: String) -> AnyPublisher<Void, UserError>
    var authStatePublisher: AnyPublisher<String?, Never> { get }
    func signOut() throws
}

class DefaultUserRepository {
    private let firebaseAuthService: AuthenticationService
    private let usersFirestoreService: UsersFirestoreService
    private let localUserService: UsersSwiftDataService
    private let modelContext: ModelContext

    init(
        firebaseAuthService: AuthenticationService = Resolver.resolve(),
        usersFirestoreService: UsersFirestoreService = Resolver.resolve(),
        localUserService: UsersSwiftDataService = Resolver.resolve(),
        modelContext: ModelContext = Resolver.resolve()
    ) {
        self.firebaseAuthService = firebaseAuthService
        self.usersFirestoreService = usersFirestoreService
        self.localUserService = localUserService
        self.modelContext = modelContext
    }
}

extension DefaultUserRepository: UserRepository {
    var authStatePublisher: AnyPublisher<String?, Never> {
        firebaseAuthService.authStatePublisher
    }

    func createUser(name: String, email: String, password: String, role: Role)
        -> AnyPublisher<String, UserError> {
        firebaseAuthService.createUser(email: email, password: password)
            .flatMap { [weak self] user -> AnyPublisher<String, UserError> in
                guard let self else {
                    return .fail(.message("Nežinoma klaida"))
                }

                let userEntity = UserMapper.mapFromUserToUserEntity(user, name: name, role: role)

                return usersFirestoreService
                    .saveUserEntity(userEntity)
                    .mapError { UserError.message($0.localizedDescription) }
                    .flatMap { _ -> AnyPublisher<String, UserError> in
                        self.localUserService
                            .saveUserEntity(userEntity)
                            .map { _ in userEntity.email }
                            .mapError { UserError.message("Klaida kuriant vartotoją: \($0.localizedDescription)") }
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func logIn(email: String, password: String) -> AnyPublisher<Void, UserError> {
        firebaseAuthService.signIn(email: email, password: password)
            .mapToVoid()
    }

    func signOut() throws {
        try firebaseAuthService.signOut()
    }
}
