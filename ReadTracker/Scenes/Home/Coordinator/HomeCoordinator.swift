import SwiftData
import SwiftUI

protocol HomeCoordinator: Coordinator {
    func presentError(
        message: String,
        onDismiss: @escaping () -> Void
    )
    func showBook(book: BookEntity, with user: UserEntity)
    func showProfile(with user: UserEntity)
}

final class DefaultHomeCoordinator: HomeCoordinator {
    private var interactor: HomeInteractor!
    private var presenter: HomePresenter!
    @Published private var viewModel: DefaultHomeViewModel!
    weak var parent: (any Coordinator)?
    @Published var presentedView: HomeCoordinatorPresentedView?
    @Published var route: HomeCoordinatorRoute?
    @Published var user: UserEntity

    init(parent: (any Coordinator)?, user: UserEntity) {
        self.user = user
        self.parent = parent
        self.viewModel = DefaultHomeViewModel()
        self.presenter = DefaultHomePresenter(displayLogic: viewModel)
        self.interactor = DefaultHomeInteractor(
            coordinator: self,
            presenter: presenter,
        )
    }

    func start() -> some View {
        HomeView(interactor: interactor, viewModel: viewModel, user: user)
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

    func showBook(book: BookEntity, with user: UserEntity) {
        presentedView = .book(book: book, user: user)
    }

    func showProfile(with user: UserEntity) {
        presentedView = .profile(user)
    }
}

// MARK: - Navigation
extension DefaultHomeCoordinator {}
