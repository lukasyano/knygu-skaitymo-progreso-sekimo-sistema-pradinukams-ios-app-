import Combine
import FirebaseAuth
import Foundation
import Resolver

protocol ProfileInteractor: AnyObject {
    func viewDidAppear()
    func createChild(name: String, email: String, password: String)
//    func onEmailChange(_ email: String)
//    func onNameChange(_ name: String)
//    func onPasswordChange(_ password: String)
//    func onRegisterTap()
}

final class DefaultProfileInteractor {
    // VIP
    private weak var presenter: ProfilePresenter?
    private weak var coordinator: (any ProfileCoordinator)?

    // Properties
    private(set) var email: String = MockCredentials.email()
    private(set) var name: String = MockCredentials.name
    private(set) var password: String = MockCredentials.password()
    private lazy var cancelBag = Set<AnyCancellable>()

    private(set) var user: UserEntity
    private(set) var childrends: [UserEntity]?
    // Repositories
    private let userRepository: UserRepository

    // MARK: - Lifecycle

    init(
        coordinator: (any ProfileCoordinator)?,
        presenter: ProfilePresenter?,
        userRepository: UserRepository = Resolver.resolve(),
        user: UserEntity
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.userRepository = userRepository
        self.user = user
        presenter?.presentUser(user)
    }
}

// MARK: - Business Logic

extension DefaultProfileInteractor: ProfileInteractor {
    func createChild(name: String, email: String, password: String) {
        userRepository.createUser(name: name, email: email, password: password, role: .child)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] in self?.handleRegistrationCompletion($0) },
                receiveValue: { [weak self] in self?.handleRegistrationSuccess(email: $0.email) }
            )
            .store(in: &cancelBag)
    }

    private func handleRegistrationSuccess(email: String) {
        
        
        print("child created")
//    let registrationSuccessMessage = "Registracija sėkminga, šaunu! Dabar galėsite prisijungti."

//    coordinator?.presentRegistrationComplete(
//        message: registrationSuccessMessage,
//        onDismiss: { [weak self] in
//            guard let self else { return }
//            coordinator?.navigateToLogin(email: email)
//        }
//    )
    }

    private func handleRegistrationCompletion(_ completion: Subscribers.Completion<UserError>) {
        presenter?.presentLoading(false)
        if case let .failure(.message(message)) = completion {
            coordinator?.presentError(error: message, onDismiss: {})
        }
    }

    // MARK: - View Did Change

    func viewDidAppear() {
        cancelBag.removeAll()
//        presenter?.presentEmail(email)
//        presenter?.presentPassword(password)
//        presenter?.presentName(name)
    }

//    func onRegisterTap() {
//        presenter?.presentLoading(true)
//
//        userRepository.createUser(name: name, email: email, password: password, role: .parent)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] in
//                    self?.handleProfileCompletion($0)
//                },
//                receiveValue: { [weak self] in
//                    self?.handleProfileSuccess(email: $0.email)
//                }
//            )
//            .store(in: &cancelBag)
//    }

//    private func handleProfileSuccess(email: String) {
//        let ProfileSuccessMessage = "Registracija sėkminga, šaunu! Dabar galėsite prisijungti."
//
//        coordinator?.presentProfileComplete(
//            message: ProfileSuccessMessage,
//            onDismiss: { [weak self] in
//                guard let self else { return }
//                coordinator?.navigateToLogin(email: email)
//            }
//        )
//    }
//
//    private func handleProfileCompletion(_ completion: Subscribers.Completion<UserError>) {
//        presenter?.presentLoading(false)
//        if case let .failure(.message(message)) = completion {
//            coordinator?.presentError(error: message, onDismiss: {})
//        }
//    }
}
