import Combine
import Foundation
import Resolver

protocol UserRepository {
    func createUser(name: String, email: String, password: String, role: Role) -> AnyPublisher<UserEntity, UserError>
    func createChildUser(name: String, email: String, password: String, parent: UserEntity) -> AnyPublisher<UserEntity, UserError>
    func logIn(email: String, password: String) -> AnyPublisher<UserEntity, UserError>
    func getCurrentUser() -> AnyPublisher<UserEntity?, Never>
    var authStatePublisher: AnyPublisher<String?, Never> { get }
    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], UserError>
    func saveUser(_ user: UserEntity) -> AnyPublisher<Void, Error>
    func signOut() throws
    var cachedRole: Role? { get }
}

final class DefaultUserRepository: UserRepository {
    @Injected private var firebaseAuth: AuthenticationService
    @Injected private var firestoreService: UsersFirestoreService
    private var cancellables = Set<AnyCancellable>()
    @Published private var currentUser: UserEntity?

    private enum Keys {
        static let userRole = "CurrentUserRole"
    }

    // MARK: - Public Interface
    var cachedRole: Role? {
        get { loadCachedRole() }
        set { newValue.map(saveCachedRole) ?? clearCachedRole() }
    }

    init() {
        setupAuthObserver()
        loadInitialRole()
    }

    func saveUser(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        firestoreService.saveUserEntity(user)
    }

    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], UserError> {
        firestoreService.getChildrenForParent(parentID: parentID)
            .mapError { UserError.message($0.localizedDescription) }
            .eraseToAnyPublisher()
    }

    func createChildUser(name: String, email: String, password: String, parent: UserEntity) -> AnyPublisher<UserEntity, UserError> {
        firebaseAuth.createUser(email: email, password: password)
            .flatMap { [weak self] firebaseUser -> AnyPublisher<UserEntity, UserError> in
                guard let self else { return .empty() }

                let child = UserEntity(
                    id: firebaseUser.uid,
                    email: email,
                    name: name,
                    role: .child,
                    parentID: parent.id,
                    childrensID: [],
                    totalPoints: 0
                )

                return self.saveAndLinkChild(child, parent: parent)
            }
            .eraseToAnyPublisher()
    }

    private func saveAndLinkChild(_ child: UserEntity, parent: UserEntity) -> AnyPublisher<UserEntity, UserError> {
        let updatedParent = parent.withAddedChild(childID: child.id)

        return Publishers.Zip(
            firestoreService.saveUserEntity(child),
            firestoreService.saveUserEntity(updatedParent)
        )
        .handleEvents(receiveOutput: { [weak self] _ in
            self?.cachedRole = parent.role // Maintain parent role
        })
        .map { _ in child }
        .mapError { UserError.message($0.localizedDescription) }
        .eraseToAnyPublisher()
    }

    func createUser(name: String, email: String, password: String, role: Role) -> AnyPublisher<UserEntity, UserError> {
        firebaseAuth.createUser(email: email, password: password)
            .flatMap { [weak self] firebaseUser -> AnyPublisher<UserEntity, UserError> in
                guard let self else { return .empty() }

                let user = UserEntity(
                    id: firebaseUser.uid,
                    email: email,
                    name: name,
                    role: role,
                    childrensID: []
                )

                return self.firestoreService.saveUserEntity(user)
                    .handleEvents(receiveOutput: { [weak self] _ in
                        self?.cachedRole = role // Save role on creation
                    })
                    .map { _ in user }
                    .mapError { UserError.message($0.localizedDescription) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func logIn(email: String, password: String) -> AnyPublisher<UserEntity, UserError> {
        firebaseAuth.signIn(email: email, password: password)
            .flatMap { [weak self] firebaseUser in
                self?.fetchAndSetCurrentUser(uid: firebaseUser.uid) ?? .empty()
            }
            .eraseToAnyPublisher()
    }

    func getCurrentUser() -> AnyPublisher<UserEntity?, Never> {
        $currentUser.eraseToAnyPublisher()
    }

    func signOut() throws {
        try firebaseAuth.signOut()
        currentUser = nil
        clearCachedRole()
    }

    var authStatePublisher: AnyPublisher<String?, Never> {
        firebaseAuth.authStatePublisher
    }

    // MARK: - Role Management
    private func loadInitialRole() {
        currentUser = cachedRole.map {
            UserEntity.temporary(role: $0)
        }
    }

    private func loadCachedRole() -> Role? {
        UserDefaults.standard.string(forKey: Keys.userRole)
            .flatMap(Role.init(rawValue:))
    }

    private func saveCachedRole(_ role: Role) {
        UserDefaults.standard.set(role.rawValue, forKey: Keys.userRole)
    }

    private func clearCachedRole() {
        UserDefaults.standard.removeObject(forKey: Keys.userRole)
    }

    // MARK: - Auth Handling
    private func setupAuthObserver() {
        authStatePublisher
            .handleEvents(receiveOutput: { [weak self] uid in
                guard let self else { return }
                if uid == nil {
                    self.clearCachedRole()
                    self.currentUser = nil
                }
            })
            .compactMap { $0 }
            .flatMap { [weak self] uid in
                self?.fetchAndSetCurrentUser(uid: uid) ?? .empty()
            }
            .sink(
                receiveCompletion: { [weak self] _ in /* ... */ },
                receiveValue: { [weak self] _ in /* ... */ }
            )
            .store(in: &cancellables)
    }

    private func fetchAndSetCurrentUser(uid: String) -> AnyPublisher<UserEntity, UserError> {
        firestoreService.getUserEntity(userID: uid)
            .handleEvents(receiveOutput: { [weak self] user in
                self?.currentUser = user
                self?.cachedRole = user.role
            })
            .mapError { UserError.message($0.localizedDescription) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Temporary User Extension
extension UserEntity {
    static func temporary(role: Role) -> UserEntity {
        UserEntity(
            id: "temp_\(UUID().uuidString)",
            email: "",
            name: "",
            role: role,
            childrensID: []
        )
    }
}
