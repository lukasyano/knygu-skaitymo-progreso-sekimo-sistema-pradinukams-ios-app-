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
    func fetchUserProgress(userID: String) -> AnyPublisher<[ProgressData], UserError>
    func signOut() throws
}

final class DefaultUserRepository: UserRepository {
    @Injected private var firebaseAuth: AuthenticationService
    @Injected private var firestoreService: UsersFirestoreService
    @Injected private var userStorageService: UserStorageService
    private var cancellables = Set<AnyCancellable>()
    @Published private var currentUser: UserEntity?

    init() {
        setupAuthObserver()
    }

    func fetchUserProgress(userID: String) -> AnyPublisher<[ProgressData], UserError> {
        firestoreService.getProgressData(userID: userID)
            .mapError { UserError.message($0.localizedDescription) }
            .handleEvents(receiveOutput: { [weak self] progress in
                self?.updateLocalUserProgress(userID: userID, progress: progress)
            })
            .eraseToAnyPublisher()
    }

    func saveUser(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        firestoreService.saveUserEntity(user)
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                self?.persistUserLocally(user) ?? .empty()
            }
            .eraseToAnyPublisher()
    }

    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], UserError> {
        firestoreService.getChildrenForParent(parentID: parentID)
            .mapError { UserError.message($0.localizedDescription) }
            .handleEvents(receiveOutput: { [weak self] children in
                self?.persistChildrenLocally(children)
            })
            .eraseToAnyPublisher()
    }

    func createChildUser(name: String, email: String, password: String, parent: UserEntity)
        -> AnyPublisher<UserEntity, UserError> {
        firebaseAuth.createUser(email: email, password: password)
            .flatMap { [weak self] firebaseUser -> AnyPublisher<UserEntity, UserError> in
                guard let self else { return .empty() }

                let child = UserEntity(
                    id: firebaseUser.uid,
                    email: email,
                    name: name,
                    role: .child,
                    parentID: parent.id,
                    childrensID: "",
                    totalPoints: 0
                )

                return self.saveAndLinkChild(child, parent: parent)
            }
            .eraseToAnyPublisher()
    }

    func createUser(name: String, email: String, password: String, role: Role) -> AnyPublisher<UserEntity, UserError> {
        firebaseAuth.createUser(email: email, password: password)
            .flatMap { [weak self] firebaseUser -> AnyPublisher<UserEntity, UserError> in
                let user = UserEntity(
                    id: firebaseUser.uid,
                    email: email,
                    name: name,
                    role: role,
                    childrensID: ""
                )

                return self?.persistUserRemotelyAndLocally(user) ?? .empty()
            }
            .eraseToAnyPublisher()
    }

    func logIn(email: String, password: String) -> AnyPublisher<UserEntity, UserError> {
        firebaseAuth.signIn(email: email, password: password)
            .flatMap { [weak self] firebaseUser in
                self?.synchronizeUserData(uid: firebaseUser.uid) ?? .empty()
            }
            .eraseToAnyPublisher()
    }

    func getCurrentUser() -> AnyPublisher<UserEntity?, Never> {
        $currentUser.eraseToAnyPublisher()
    }

    func signOut() throws {
        try firebaseAuth.signOut()
        currentUser = nil
    }

    var authStatePublisher: AnyPublisher<String?, Never> {
        firebaseAuth.authStatePublisher
    }

    private func setupAuthObserver() {
        authStatePublisher
            .handleEvents(receiveOutput: { [weak self] uid in
                guard let self, uid == nil else { return }
                currentUser = nil
            })
            .compactMap { $0 }
            .flatMap { [weak self] uid in
                self?.synchronizeUserData(uid: uid) ?? .empty()
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func synchronizeUserData(uid: String) -> AnyPublisher<UserEntity, UserError> {
        let localUser = try? userStorageService.fetchUser(byId: uid)

        return firestoreService.getUserEntity(userID: uid)
            .flatMap { [weak self] remoteUser -> AnyPublisher<UserEntity, Error> in
                guard let self else { return .empty() }
                return synchronizeRelatedData(for: remoteUser)
                    .map { _ in remoteUser }
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] user in
                self?.currentUser = user
                try? self?.userStorageService.saveUser(user)
            })
            .mapError { UserError.message($0.localizedDescription) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Sync Helpers
private extension DefaultUserRepository {
    func persistUserLocally(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try self.userStorageService.saveUser(user)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func persistChildrenLocally(_ children: [UserEntity]) {
        children.forEach { try? userStorageService.saveUser($0) }
    }

    
    //TODO: - 
    func updateLocalUserProgress(userID: String, progress: [ProgressData]) {
        guard var user = try? userStorageService.fetchUser(byId: userID) else { return }
        user.progressData = progress
        try? userStorageService.saveUser(user)
    }

    func synchronizeRelatedData(for user: UserEntity) -> AnyPublisher<Void, UserError> {
        var publishers = [AnyPublisher<Void, UserError>]()

        // Sync children if parent
        if user.role == .parent {
            let childrenSync = getChildrenForParent(parentID: user.id)
                .map { _ in () }
                .eraseToAnyPublisher()
            publishers.append(childrenSync)
        }

        // Sync progress if child
        if user.role == .child {
            let progressSync = fetchUserProgress(userID: user.id)
                .map { _ in () }
                .eraseToAnyPublisher()
            publishers.append(progressSync)
        }

        return Publishers.MergeMany(publishers)
            .mapError { UserError.message($0.localizedDescription) }
            .eraseToAnyPublisher()
    }

    func saveAndLinkChild(_ child: UserEntity, parent: UserEntity) -> AnyPublisher<UserEntity, UserError> {
        let updatedParent = parent.withAddedChild(child)

        return Publishers.Zip(
            persistUserRemotelyAndLocally(child),
            persistUserRemotelyAndLocally(updatedParent)
        )
        .map { _ in child }
        .eraseToAnyPublisher()
    }

    func persistUserRemotelyAndLocally(_ user: UserEntity) -> AnyPublisher<UserEntity, UserError> {
        firestoreService.saveUserEntity(user)
            .flatMap { [weak self] _ in
                self?.persistUserLocally(user)
                    .map { _ in user }
                    .eraseToAnyPublisher() ?? .empty()
            }
            .mapError { UserError.message($0.localizedDescription) }
            .eraseToAnyPublisher()
    }
}
