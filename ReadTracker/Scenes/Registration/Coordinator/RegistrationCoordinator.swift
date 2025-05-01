import SwiftUI

protocol RegistrationCoordinator: Coordinator {
    func presentError(
        error: String,
        onDismiss: @escaping () -> Void
    )
    func presentRegistrationComplete(
        message: String,
        onDismiss: @escaping () -> Void
    )
    func navigateToLogin(email: String)
}

final class DefaultRegistrationCoordinator: RegistrationCoordinator {
    private var interactor: RegistrationInteractor!
    private var presenter: RegistrationPresenter!
    @Published private var viewModel: DefaultRegistrationViewModel!
    weak var parent: (any Coordinator)?
    @Published var presentedView: RegistrationCoordinatorPresentedView?
    @Published var route: RegistrationCoordinatorRoute?

    init(parent: (any Coordinator)?) {
        self.parent = parent
        self.viewModel = DefaultRegistrationViewModel()
        self.presenter = DefaultRegistrationPresenter(displayLogic: viewModel)
        self.interactor = DefaultRegistrationInteractor(
            coordinator: self,
            presenter: presenter
        )
    }

    func start() -> some View {
        RegistrationView(interactor: interactor, viewModel: viewModel)
    }
}

// MARK: - Presentation

extension DefaultRegistrationCoordinator {
    func presentError(
        error: String,
        onDismiss: @escaping () -> Void
    ) {
        presentedView = .validationError(error: error, onDismiss: onDismiss)
    }

    func presentRegistrationComplete(
        message: String,
        onDismiss: @escaping () -> Void
    ) {
        presentedView = .infoMessage(message: message, onDismiss: onDismiss)
    }
}

// MARK: - Navigation

extension DefaultRegistrationCoordinator {
    func navigateToLogin(email: String) {
        route = .login(email)
    }
}
