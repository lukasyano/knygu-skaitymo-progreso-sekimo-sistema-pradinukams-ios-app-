import Combine
import FirebaseAuth
import Foundation
import Resolver

protocol RegistrationInteractor: AnyObject {
    func viewDidAppear()
    func onEmailChange(_ email: String)
    func onNameChange(_ name: String)
    func onPasswordChange(_ password: String)
    func onRegisterTap()
}

final class DefaultRegistrationInteractor {
    // VIP
    private weak var presenter: RegistrationPresenter?
    private weak var coordinator: (any RegistrationCoordinator)?

    // Properties
    private(set) var email: String = ""
    private(set) var name: String = ""
    private(set) var password: String = ""
    private lazy var cancelBag = Set<AnyCancellable>()

    // Repositories
    private let userRepository: UserRepository

    // MARK: - Lifecycle

    init(
        coordinator: (any RegistrationCoordinator)?,
        presenter: RegistrationPresenter?,
        userRepository: UserRepository = Resolver.resolve()
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.userRepository = userRepository
    }
}

// MARK: - Business Logic

extension DefaultRegistrationInteractor: RegistrationInteractor {
    func onEmailChange(_ email: String) {
        self.email = email
        presenter?.presentEmail(email)
    }

    func onNameChange(_ name: String) {
        self.name = name
        presenter?.presentName(name)
    }

    func onPasswordChange(_ password: String) {
        self.password = password
        presenter?.presentPassword(password)
    }

    // MARK: - View Did Change

    func viewDidAppear() {
        cancelBag.removeAll()
    }

    func onRegisterTap() {
        presenter?.presentLoading(true)

        userRepository.createUser(name: name, email: email, password: password, role: .parent)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] in
                    self?.handleRegistrationCompletion($0)
                },
                receiveValue: { [weak self] in
                    self?.handleRegistrationSuccess(email: $0.email)
                }
            )
            .store(in: &cancelBag)
    }

    private func handleRegistrationSuccess(email: String) {
        let registrationSuccessMessage = "Registracija sėkminga, šaunu! Dabar galėsite prisijungti."

        coordinator?.presentRegistrationComplete(
            message: registrationSuccessMessage,
            onDismiss: { [weak self] in
                guard let self else { return }
                coordinator?.navigateToLogin(email: email)
            }
        )
    }

    private func handleRegistrationCompletion(_ completion: Subscribers.Completion<UserError>) {
        presenter?.presentLoading(false)
        if case let .failure(.message(message)) = completion {
            coordinator?.presentError(error: message, onDismiss: {})
        }
    }
}
