import SwiftUI

protocol LoginCoordinator: Coordinator {
    func presentError(_ error: String, onClose: @escaping () -> Void)
    func presentLoginComplete(_ message: String, onClose: @escaping () -> Void)
    func navigateToHome(userID: String)
}

final class DefaultLoginCoordinator: LoginCoordinator {
    private var interactor: LoginInteractor!
    private var presenter: LoginPresenter!
    @Published private var viewModel: DefaultLoginViewModel!
    weak var parent: (any Coordinator)?
    @Published var presentedView: LoginCoordinatorPresentedView?
    @Published var route: LoginCoordinatorRoute?

    init(parent: (any Coordinator)?, email: String?, shouldAutoNavigateToHome: Bool) {
        self.parent = parent
        self.viewModel = DefaultLoginViewModel()
        self.presenter = DefaultLoginPresenter(displayLogic: viewModel)
        self.interactor = DefaultLoginInteractor(
            coordinator: self,
            presenter: presenter,
            email: email,
            shouldAutoNavigateToHome: shouldAutoNavigateToHome
        )
    }

    func start() -> some View {
        LoginView(interactor: interactor, viewModel: viewModel)
    }
}

// MARK: - Presentation

extension DefaultLoginCoordinator {
    func presentError(_ error: String, onClose: @escaping () -> Void){
        presentedView = .validationError(error: error, onClose: onClose)
    }

    func presentLoginComplete(_ message: String, onClose: @escaping () -> Void) {
        presentedView = .infoMessage(message: message, onClose: onClose)
    }
}

// MARK: - Navigation

extension DefaultLoginCoordinator {
    func navigateToHome(userID: String) {
        route = .home(userID: userID)
    }
}
