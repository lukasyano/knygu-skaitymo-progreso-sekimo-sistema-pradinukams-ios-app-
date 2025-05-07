import SwiftUI

protocol ProfileCoordinator: Coordinator {
    func presentError(
        error: String,
        onDismiss: @escaping () -> Void
    )
    func presentProfileComplete(
        message: String,
        onDismiss: @escaping () -> Void
    )
    func navigateToLogin(email: String)
}

final class DefaultProfileCoordinator: ProfileCoordinator {
    private var interactor: ProfileInteractor!
    private var presenter: ProfilePresenter!
    @Published private var viewModel: DefaultProfileViewModel!
    weak var parent: (any Coordinator)?
    @Published var presentedView: ProfileCoordinatorPresentedView?
    @Published var route: ProfileCoordinatorRoute?

    init(user: UserEntity, parent: (any Coordinator)?) {
        self.parent = parent
        self.viewModel = DefaultProfileViewModel()
        self.presenter = DefaultProfilePresenter(displayLogic: viewModel)
        self.interactor = DefaultProfileInteractor(
            coordinator: self,
            presenter: presenter,
            user: user
        )
    }

    func start() -> some View {
        ProfileView(interactor: interactor, viewModel: viewModel)
    }
}

// MARK: - Presentation

extension DefaultProfileCoordinator {
    func presentError(
        error: String,
        onDismiss: @escaping () -> Void
    ) {
        presentedView = .validationError(error: error, onDismiss: onDismiss)
    }

    func presentProfileComplete(
        message: String,
        onDismiss: @escaping () -> Void
    ) {
        presentedView = .infoMessage(message: message, onDismiss: onDismiss)
    }
}

// MARK: - Navigation

extension DefaultProfileCoordinator {
    func navigateToLogin(email: String) {
        popToParent()
        route = .login(email)
    }
}
