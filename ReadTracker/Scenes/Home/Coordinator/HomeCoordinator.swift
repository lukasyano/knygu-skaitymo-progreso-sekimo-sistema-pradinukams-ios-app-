import SwiftUI

protocol HomeCoordinator: Coordinator {}

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
            presenter: presenter
        )
    }

    func start() -> some View {
        HomeView(interactor: interactor, viewModel: viewModel)
    }
}

// MARK: - Presentation
extension DefaultHomeCoordinator {}

// MARK: - Navigation
extension DefaultHomeCoordinator {}
