import Combine
import FirebaseAuth
import Foundation
import Resolver

protocol LoginInteractor: AnyObject {
    func viewDidChange(_ type: ViewDidChangeType)
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
    private let authRepository: AuthenticationRepository

    // MARK: - Lifecycle
    init(
        coordinator: (any LoginCoordinator)?,
        presenter: LoginPresenter?,
        authRepository: AuthenticationRepository = Resolver.resolve(),
        email: String?,
        shouldAutoNavigateToHome: Bool
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.authRepository = authRepository
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
    func viewDidChange(_ type: ViewDidChangeType) {
        switch type {
        case .onAppear:
            cancelBag.removeAll()
            presenter?.presentEmail(email)
            presenter?.presentPassword(password)

        case .onDisappear:
            presenter?.presentLoading(false)
            cancelBag.removeAll()
        }
    }

    func onLoginTap() {
        presenter?.presentLoading(true)

        authRepository.signIn(email: email, password: password, remember: rememberMe)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] in self?.handleLoginCompletion($0) },
                receiveValue: { [weak coordinator] _ in coordinator?.navigateToHome() }
            )
            .store(in: &cancelBag)
    }

    private func handleLoginCompletion(_ completion: Subscribers.Completion<AuthUIError>) {
        if case let .failure(error) = completion {
            guard let errorMessage = error.errorDescription else { return }

            coordinator?.presentError(errorMessage, onClose: { self.presenter?.presentLoading(false) })
        }
    }
}
