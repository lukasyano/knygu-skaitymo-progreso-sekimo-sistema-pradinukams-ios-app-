import SwiftUI
import SwiftData

protocol HomeCoordinator: Coordinator {
    func presentError(
        message: String,
        onDismiss: @escaping () -> Void
    )
    func showBook(at url: URL)
    func showProfile(with user: UserEntity)
}

final class DefaultHomeCoordinator: HomeCoordinator {
    private var interactor: HomeInteractor!
    private var presenter: HomePresenter!
    @Published private var viewModel: DefaultHomeViewModel!
    weak var parent: (any Coordinator)?
    @Published var presentedView: HomeCoordinatorPresentedView?
    @Published var route: HomeCoordinatorRoute?

    init(parent: (any Coordinator)?) {
        self.parent = parent
        self.viewModel = DefaultHomeViewModel()
        self.presenter = DefaultHomePresenter(displayLogic: viewModel)
        self.interactor = DefaultHomeInteractor(
            coordinator: self,
            presenter: presenter,
        )
    }

    func start() -> some View {
        HomeView(interactor: interactor, viewModel: viewModel)
    }
}

// MARK: - Presentation
extension DefaultHomeCoordinator {
    func presentError(
        message: String,
        onDismiss: @escaping () -> Void
    ) {
        presentedView = .error(error: message, dismiss: onDismiss)
    }
    
    func showBook(at url: URL) {
        presentedView = .book(url: url)
    }
    
    func showProfile(with user: UserEntity) {
        presentedView = .profile(user)
    }
}

// MARK: - Navigation
extension DefaultHomeCoordinator {}
