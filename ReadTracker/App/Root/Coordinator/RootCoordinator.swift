import Resolver
import SwiftData
import SwiftUI


final class DefaultRootCoordinator: Coordinator {
//    private var interactor: RootInteractor!

    weak var parent: (any Coordinator)?
    @Published var presentedView: None?
    @Published var route: RootCoordinatorRoute? = .splash

//    init(modelContext: ModelContext) {
//        self.modelContext = modelContext
////        self.interactor = DefaultRootInteractor(coordinator: self, modelContext: modelContext)
//    }

    @ViewBuilder
    func start() -> some View {
//        RootView(interactor: interactor)
    }
}

// MARK: - Presentation

extension DefaultRootCoordinator {}

// MARK: - Navigation

extension DefaultRootCoordinator {

}
