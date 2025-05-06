import Combine
import FirebaseAuth
import Foundation
import Resolver

protocol LoginInteractor: AnyObject {
    func viewDidAppear()
    func onEmailChange(_ email: String)
    func onPasswordChange(_ password: String)
    func onRememberMeToggle()
    func onLoginTap()
}

final class DefaultLoginInteractor {
    // VIP
    private weak var presenter: LoginPresenter?
    private weak var coordinator: (any LoginCoordinator)?

    // Properties
    private(set) var email: String = MockCredentials.email()
    private(set) var password: String = MockCredentials.password()
    private(set) var rememberMe: Bool = false

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
        if let email = email {
            self.email = email
        }
        if shouldAutoNavigateToHome {
            coordinator?.navigateToHome()
        }
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

    func onRememberMeToggle() {
        rememberMe.toggle()
        presenter?.presentRememberMe(rememberMe)
    }

    // MARK: - View Did Change
    func viewDidAppear() {
        cancelBag.removeAll()
        presenter?.presentEmail(email)
        presenter?.presentPassword(password)
    }

    func onLoginTap() {
        presenter?.presentLoading(true)

        userRepository.logIn(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] in self?.handleLoginCompletion($0) },
                receiveValue: { [weak coordinator] _ in coordinator?.navigateToHome() }
            )
            .store(in: &cancelBag)
    }

    private func handleLoginCompletion(_ completion: Subscribers.Completion<UserError>) {
        presenter?.presentLoading(false)
        
        if case let .failure(.message(message)) = completion {
            coordinator?.presentError(message, onClose: {})
        }
    }
}
