import Combine
import Foundation
import Resolver
import SwiftData

protocol UserRepository {
    func createUser(name: String, email: String, password: String, role: Role) -> AnyPublisher<UserEntity, UserError>
    func createChildUser(
        name: String,
        email: String,
        password: String,
        parent: UserEntity
    ) -> AnyPublisher<UserEntity, UserError>
    func logIn(email: String, password: String) -> AnyPublisher<UserEntity, UserError>
    func getCurrentUser() -> AnyPublisher<UserEntity?, Never>
    var authStatePublisher: AnyPublisher<String?, Never> { get }
    func signOut() throws
}

final class DefaultUserRepository: UserRepository {
    private let firebaseAuthenticationService: AuthenticationService
    private let usersFirestoreService: UsersFirestoreService
    private let localUsersService: LocalUsersService
    private var cancellables = Set<AnyCancellable>()

    init(
        firebaseAuthenticationService: AuthenticationService = Resolver.resolve(),
        usersFirestoreService: UsersFirestoreService = Resolver.resolve(),
        localUsersService: LocalUsersService = Resolver.resolve()
    ) {
        self.firebaseAuthenticationService = firebaseAuthenticationService
        self.usersFirestoreService = usersFirestoreService
        self.localUsersService = localUsersService
        setupAuthObserver()
    }

    func createChildUser(name: String, email: String, password: String, parent: UserEntity) -> AnyPublisher<UserEntity, UserError> {
        let parentID = parent.id

        return firebaseAuthenticationService.createUser(email: email, password: password)
            .flatMap { [weak self] firebaseUser -> AnyPublisher<UserEntity, UserError> in
                guard let self else { return .fail(.message("System error")) }

                let childEntity = UserEntity(
                    id: firebaseUser.uid,
                    email: email,
                    name: name,
                    role: .child,
                    parentID: parentID,
                    childrensID: [],
                    points: 0
                )

                return self.saveAndLinkChild(childEntity, parentUID: parentID)
                    .flatMap { child -> AnyPublisher<UserEntity, UserError> in
                        self.firebaseAuthenticationService.reauthenticate()
                            .map { _ in child }
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func saveAndLinkChild(_ child: UserEntity, parentUID: String) -> AnyPublisher<UserEntity, UserError> {
        // 1. Save child to Firestore first
        let saveChildPublisher = usersFirestoreService.saveUserEntity(child)
            .mapError { UserError.message($0.localizedDescription) }
            .eraseToAnyPublisher()

        let updateParentPublisher: AnyPublisher<Void, UserError> = saveChildPublisher
            .flatMap { _ in
                self.usersFirestoreService.updateParentWithChild(parentID: parentUID, childID: child.id)
                    .mapError { UserError.message($0.localizedDescription) }
            }
            .eraseToAnyPublisher()

//        let updateLocalPublisher: AnyPublisher<Void, UserError> = updateParentPublisher
//            .flatMap { _ in
//                self.localUsersService.addChildToParent(parentID: parentUID, childID: child.id)
//                    .mapError { UserError.message($0.localizedDescription) }
//            }
//            .eraseToAnyPublisher()

        return updateParentPublisher
            .map { _ in child }
            .eraseToAnyPublisher()
    }

    func createUser(name: String, email: String, password: String, role: Role) -> AnyPublisher<UserEntity, UserError> {
        firebaseAuthenticationService.createUser(email: email, password: password)
            .flatMap { [weak self] firebaseUser -> AnyPublisher<UserEntity, UserError> in
                guard let self else { return .fail(.message("System error")) }

                let userEntity = UserEntity(
                    id: firebaseUser.uid,
                    email: email,
                    name: name,
                    role: role,
                    parentID: nil,
                    childrensID: [],
                    points: 0
                )

                return self.saveUser(entity: userEntity)
            }
            .eraseToAnyPublisher()
    }

    func logIn(email: String, password: String) -> AnyPublisher<UserEntity, UserError> {
        clearExistingUserData()
            .flatMap { [weak self] _ -> AnyPublisher<UserEntity, UserError> in
                guard let self else { return .fail(.message("Session expired")) }

                return self.firebaseAuthenticationService.signIn(email: email, password: password)
                    .flatMap { self.syncUserData(uid: $0.uid) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func getCurrentUser() -> AnyPublisher<UserEntity?, Never> {
        localUsersService.getCurrentUser()
    }

    func signOut() throws {
        try firebaseAuthenticationService.signOut()
        clearLocalUserData()
    }

    // MARK: - Auth State
    var authStatePublisher: AnyPublisher<String?, Never> {
        firebaseAuthenticationService.authStatePublisher
    }

    private func setupAuthObserver() {
        authStatePublisher
            .sink { [weak self] uid in
                guard let self else { return }

                if let uid {
                    self.syncUserData(uid: uid)
                        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                        .store(in: &self.cancellables)
                } else {
                    self.clearLocalUserData()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Data Management
private extension DefaultUserRepository {
    func syncUserData(uid: String) -> AnyPublisher<UserEntity, UserError> {
        usersFirestoreService.getUserEntity(userID: uid)
            .mapError { UserError.message($0.localizedDescription) }
            .flatMap { [weak self] remoteUser -> AnyPublisher<UserEntity, UserError> in
                guard let self else { return .fail(.message("Session expired")) }

                return self.saveUser(entity: remoteUser)
            }
            .eraseToAnyPublisher()
    }

    func saveUser(entity: UserEntity) -> AnyPublisher<UserEntity, UserError> {
        Publishers.Zip(
            localUsersService.saveUserEntity(entity),
            usersFirestoreService.saveUserEntity(entity)
        )
        .map { _ in entity }
        .mapError { UserError.message($0.localizedDescription) }
        .eraseToAnyPublisher()
    }

    func clearExistingUserData() -> AnyPublisher<Void, UserError> {
        localUsersService.clearAllUsers()
            .mapError { UserError.message($0.localizedDescription) }
            .eraseToAnyPublisher()
    }

    func clearLocalUserData() {
        localUsersService.clearAllUsers()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
