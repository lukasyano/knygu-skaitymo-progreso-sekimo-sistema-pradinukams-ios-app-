import SwiftUI

protocol LoginCoordinator: AnyObject {
    func presentError(_ error: String)
    func presentLoginComplete(_ message: String)
    func navigateToMain()
}

final class DefaultLoginCoordinator: Coordinator, LoginCoordinator {
    private var interactor: LoginInteractor!
    private var presenter: LoginPresenter!
    @Published private var viewModel: DefaultLoginViewModel!
    weak var parent: (any Coordinator)?
    @Published var presentedView: LoginCoordinatorPresentedView?
    @Published var route: LoginCoordinatorRoute?

    init(parent: (any Coordinator)?, email: String?) {
        self.parent = parent
        self.viewModel = DefaultLoginViewModel()
        self.presenter = DefaultLoginPresenter(displayLogic: viewModel)
        self.interactor = DefaultLoginInteractor(
            coordinator: self,
            presenter: presenter,
            email: email
        )
    }

    func start() -> some View {
        LoginView(interactor: interactor, viewModel: viewModel)
    }
}

// MARK: - Presentation

extension DefaultLoginCoordinator {
    func presentError(_ error: String) {
        presentedView = .validationError(error: error)
    }

    func presentLoginComplete(_ message: String) {
        presentedView = .infoMessage(message: message)
    }
}

// MARK: - Navigation

extension DefaultLoginCoordinator {
    func navigateToMain() {
        route = .main
    }
}
