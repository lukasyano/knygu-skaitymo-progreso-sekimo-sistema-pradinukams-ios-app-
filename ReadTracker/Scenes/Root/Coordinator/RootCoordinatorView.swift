import Resolver
import SwiftData
import SwiftUI

struct RootCoordinatorView: View {
    @ObservedObject var coordinator: DefaultRootCoordinator
    private let interactor: RootInteractor

    init(
        coordinator: DefaultRootCoordinator,
        interactor: DefaultRootInteractor
    ) {
        self.coordinator = coordinator
        self.interactor = interactor
    }

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            contentView
                .transition(.opacity)
                .onAppear { [weak interactor] in interactor?.onAppear() }
                .onDisappear { [weak interactor] in interactor?.onDisappear() }
        }
        .animation(.bouncy, value: coordinator.route)
    }

    @ViewBuilder
    private var contentView: some View {
        switch coordinator.route {
//        case .authentication:
//            AuthenticationCoordinatorView(coordinator: Resolver.resolve())

        case .carousel: LoadingView()
            
        case .home:
            HomeCoordinatorView(coordinator: .init(parent: coordinator))

        default:
            AuthenticationCoordinatorView(coordinator: Resolver.resolve())
        }
    }
}
