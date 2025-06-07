import Combine
import Foundation
import Resolver

protocol UserRepository {
    func createUser(name: String, email: String, password: String, role: Role) -> AnyPublisher<UserEntity, UserError>
    func createChildUser(name: String, email: String, password: String, parent: UserEntity)
        -> AnyPublisher<UserEntity, UserError>
    func logIn(email: String, password: String) -> AnyPublisher<UserEntity, UserError>
    func getCurrentUser() -> AnyPublisher<UserEntity?, Never>
    var authStatePublisher: AnyPublisher<String?, Never> { get }
    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], UserError>
    func saveUser(_ user: UserEntity) -> AnyPublisher<Void, Error>
    func saveUserDailyTarget(userID: String, goal: Int)
    func fetchUserProgress(userID: String) -> AnyPublisher<[ProgressData], UserError>
    func saveReadingSession(_ session: ReadingSession, for userId: String) -> AnyPublisher<Void, Error>
    func getWeeklyStats(userID: String) -> AnyPublisher<WeeklyReadingStats, UserError>
    func getReadingSessions(userID: String) -> AnyPublisher<[ReadingSession], UserError>
    func getProgressHistory(userID: String) -> AnyPublisher<[ProgressData], UserError>

    func signOut() throws
}

final class DefaultUserRepository: UserRepository {
    func saveUserDailyTarget(userID: String, goal: Int) {
        firestoreService.setDailyGoal(userId: userID, goal: goal)
    }

    func saveReadingSession(_ session: ReadingSession, for userId: String) -> AnyPublisher<Void, Error> {
        firestoreService.saveReadingSession(userID: userId, session: session)
            .retry(3) // Retry on failure
            .delay(for: .seconds(1), scheduler: DispatchQueue.global())
            .eraseToAnyPublisher()
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getWeeklyStats(userID: String) -> AnyPublisher<WeeklyReadingStats, UserError> {
        firestoreService.getWeeklyStats(userID: userID)
            .mapError { UserError.message($0.localizedDescription) }
            .eraseToAnyPublisher()
    }

    func getReadingSessions(userID: String) -> AnyPublisher<[ReadingSession], UserError> {
        firestoreService.getReadingSessions(userID: userID)
            .mapError { UserError.message($0.localizedDescription) }
            .eraseToAnyPublisher()
    }

    func getProgressHistory(userID: String) -> AnyPublisher<[ProgressData], UserError> {
        firestoreService.getProgressData(userID: userID)
            .mapError { UserError.message($0.localizedDescription) }
            .eraseToAnyPublisher()
    }

    private var firebaseAuth: AuthenticationService
    private var firestoreService: UsersFirestoreService
    private var userStorageService: UserStorageService

    init(
        firebaseAuth: AuthenticationService = Resolver.resolve(),
        firestoreService: UsersFirestoreService = Resolver.resolve(),
        userStorageService: UserStorageService = Resolver.resolve()
    ) {
        self.firebaseAuth = firebaseAuth
        self.firestoreService = firestoreService
        self.userStorageService = userStorageService
    }

    private var cancellables = Set<AnyCancellable>()
    @Published private var currentUser: UserEntity?

    func fetchUserProgress(userID: String) -> AnyPublisher<[ProgressData], UserError> {
        firestoreService.getProgressData(userID: userID)
            .removeDuplicates()
            .mapError { UserError.message($0.localizedDescription) }
            .handleEvents(receiveOutput: { [weak self] progress in
                self?.updateLocalUserProgress(userID: userID, progress: progress)
            })
            .eraseToAnyPublisher()
    }

    func saveUser(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        print("Save user called!")
        return firestoreService.saveUserEntity(user)
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
            .debounce(for: .seconds(10), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .flatMap { [weak self] uid -> AnyPublisher<UserEntity, UserError> in
                self?.synchronizeUserData(uid: uid) ?? .empty()
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func synchronizeUserData(uid: String) -> AnyPublisher<UserEntity, UserError> {
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

    func updateLocalUserProgress(userID: String, progress: [ProgressData]) {
        guard let user = try? userStorageService.fetchUser(byId: userID) else { return }
        user.progressData = progress
        try? userStorageService.saveUser(user)
    }

    func synchronizeRelatedData(for user: UserEntity) -> AnyPublisher<Void, UserError> {
        var publishers = [AnyPublisher<Void, UserError>]()

        if user.role == .parent {
            let childrenSync = getChildrenForParent(parentID: user.id)
                .map { _ in () }
                .eraseToAnyPublisher()
            publishers.append(childrenSync)
        }

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
        persistUserRemotelyAndLocally(child)
            .flatMap { [weak self] _ -> AnyPublisher<UserEntity, UserError> in
                guard let self else { return .empty() }
                let updatedParent = parent.withAddedChild(child)
                return self.persistUserRemotelyAndLocally(updatedParent)
            }
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
