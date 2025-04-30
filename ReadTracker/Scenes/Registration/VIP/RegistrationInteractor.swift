import Combine
import FirebaseAuth
import Foundation
import Resolver

protocol RegistrationInteractor: AnyObject {
    func viewDidChange(_ type: ViewDidChangeType)
    func onEmailChange(_ email: String)
    func onPasswordChange(_ password: String)
    func onRoleChange(_ role: Role)
    func onRegisterTap()
}

final class DefaultRegistrationInteractor {
    // VIP
    private weak var presenter: RegistrationPresenter?
    private weak var coordinator: RegistrationCoordinator?

    // Properties
    private(set) var email: String = ""
    private(set) var password: String = ""
    private(set) var roleSelection = RegistrationModels.RoleSelection(
        selected: .child,
        availableRoles: [.child, .parent]
    )
    private lazy var cancelBag = Set<AnyCancellable>()

    // Repositories
    private let authRepository: AuthenticationRepository

    // MARK: - Lifecycle

    init(
        coordinator: any RegistrationCoordinator,
        presenter: RegistrationPresenter,
        authRepository: AuthenticationRepository = Resolver.resolve()
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.authRepository = authRepository
    }
}

// MARK: - Business Logic

extension DefaultRegistrationInteractor: RegistrationInteractor {
    func onEmailChange(_ email: String) {
        self.email = email
        presenter?.presentEmail(email)
    }

    func onPasswordChange(_ password: String) {
        self.password = password
        presenter?.presentPassword(password)
    }

    func onRoleChange(_ role: Role) {
        roleSelection.selected = role
        presenter?.presentRoleSelection(roleSelection)
    }

    // MARK: - View Did Change

    func viewDidChange(_ type: ViewDidChangeType) {
        switch type {
        case .onAppear:
            cancelBag.removeAll()

        case .onDisappear:
            presenter?.presentLoading(false)
            cancelBag.removeAll()
        }
    }

    func onRegisterTap() {
        authRepository.signUp(email: email, password: password, role: .child)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] in self?.handleRegistrationCompletion($0) },
                receiveValue: { [weak self] in self?.handleRegistrationSuccess($0) }
            )
            .store(in: &cancelBag)
    }

    private func handleRegistrationSuccess(_ user: User) {
        print(user.uid)
    }

    private func handleRegistrationCompletion(_ completion: Subscribers.Completion<AuthUIError>) {
        if case let .failure(error) = completion {
            coordinator?.presentError(error.errorDescription ?? "")

            print(error.localizedDescription)
        }
    }
}
