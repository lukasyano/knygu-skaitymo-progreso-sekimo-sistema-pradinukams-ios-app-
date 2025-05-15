import Combine
import FirebaseAuth
import Foundation
import Resolver

protocol ProfileInteractor: AnyObject {
    func viewDidAppear()
    func createChild(name: String, email: String, password: String, user: UserEntity)
    func updateChildDailyGoal(user: UserEntity, goal: Int)
}

final class DefaultProfileInteractor {
    // VIP
    private weak var presenter: ProfilePresenter?
    private weak var coordinator: (any ProfileCoordinator)?

    // Properties
    private(set) var email: String = ""
    private(set) var name: String = ""
    private(set) var password: String = ""
    private lazy var cancelBag = Set<AnyCancellable>()

    private(set) var userID: String

    // Repositories
    @Injected private var userRepository: UserRepository

    // MARK: - Lifecycle

    init(
        coordinator: (any ProfileCoordinator)?,
        presenter: ProfilePresenter?,
        userID: String
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.userID = userID
    }
}

// MARK: - Business Logic

extension DefaultProfileInteractor: ProfileInteractor {
    func updateChildDailyGoal(user: UserEntity, goal: Int) {
        var updatedUser = user
        updatedUser.dailyReadingGoal = goal

       // userRepository.saveUserDailyTarget(userID: user.id, goal: goal)

        userRepository.saveUser(updatedUser)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancelBag)
    }

    func createChild(name: String, email: String, password: String, user: UserEntity) {
        presenter?.presentLoading(true)

        let parent = user
        userRepository.createChildUser(
            name: name,
            email: email,
            password: password,
            parent: parent
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] in self?.handleRegistrationCompletion($0) },
            receiveValue: { [weak self] in self?.handleRegistrationSuccess($0) }
        )
        .store(in: &cancelBag)
    }

    private func handleRegistrationSuccess(_ user: UserEntity) {
        coordinator?.presentProfileComplete(
            message: "Vaikas sėkmingai sukurtas bei priskirtas prie jūsų profilio",
            onDismiss: { [weak self] in
                self?.presenter?.presentLoading(false)
                do {
                    try self?.userRepository.signOut()
                } catch {}
            }
        )
    }

    private func handleRegistrationCompletion(_ completion: Subscribers.Completion<UserError>) {
        if case let .failure(.message(message)) = completion {
            presenter?.presentLoading(false)
            coordinator?.presentError(error: message, onDismiss: {})
        }
    }

    // MARK: - View Did Change

    func viewDidAppear() {
        cancelBag.removeAll()
    }
}
