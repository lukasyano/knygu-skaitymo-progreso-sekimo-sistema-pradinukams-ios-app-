import Combine
import FirebaseAuth
import Foundation
import Resolver

protocol LoginInteractor: AnyObject {
    func viewDidAppear()
    func viewDidDisappear()
    func onEmailChange(_ email: String)
    func onPasswordChange(_ password: String)
    func onLoginTap()
}

final class DefaultLoginInteractor {
    // VIP
    private weak var presenter: LoginPresenter?
    private weak var coordinator: (any LoginCoordinator)?

    // Properties
    private(set) var email: String = MockCredentials.email()
    private(set) var password: String = MockCredentials.password()

    private lazy var cancelBag = Set<AnyCancellable>()

    // Repositories
    private let userRepository: UserRepository

    // MARK: - Lifecycle
    init(
        coordinator: (any LoginCoordinator)?,
        presenter: LoginPresenter?,
        userRepository: UserRepository = Resolver.resolve(),
        email: String?,
        shouldAutoNavigateToHome: Bool
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.userRepository = userRepository
    }
}

// MARK: - Business Logic
extension DefaultLoginInteractor: LoginInteractor {
    func onEmailChange(_ email: String) {
        self.email = email
        presenter?.presentEmail(email)
    }

    func onPasswordChange(_ password: String) {
        self.password = password
        presenter?.presentPassword(password)
    }

    // MARK: - View Did Change
    func viewDidAppear() {
        cancelBag.removeAll()
        presenter?.presentEmail(email)
        presenter?.presentPassword(password)
    }

    func viewDidDisappear() {
        cancelBag.removeAll()
    }

    func onLoginTap() {
        presenter?.presentLoading(true)

        userRepository.logIn(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] in self?.handleLoginCompletion($0) },
                receiveValue: { [weak coordinator] user in coordinator?.navigateToHome(userID: user.id) }
            )
            .store(in: &cancelBag)
    }

    private func handleLoginCompletion(_ completion: Subscribers.Completion<UserError>) {
        if case let .failure(.message(message)) = completion {
            coordinator?.presentError(message, onClose: { [weak presenter] in
                presenter?.presentLoading(false)
            })
        }
    }
}
