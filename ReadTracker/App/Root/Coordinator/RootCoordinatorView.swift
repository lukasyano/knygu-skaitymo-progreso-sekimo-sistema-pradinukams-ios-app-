import Lottie
import Resolver
import SwiftUI

struct RootCoordinatorView: View {
    @Environment(\.modelContext) private var modelContext

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
                .transition(.slide)
                .onAppDidBecomeActive { [weak interactor] in interactor?.onAppDidBecomeActive() }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.route)
    }

    @ViewBuilder
    private var contentView: some View {
        switch coordinator.route {
        case .splash:
            EmptyView()
        case .authentication:
            AuthenticationCoordinatorView(coordinator: .init(modelContext: modelContext))
        case .carousel:
            LoadingIndicator(animation: .text, size: .large)
        case .login:
            LoginCoordinatorView(coordinator: .init(parent: coordinator, email: .none))
        case .register:
            RegistrationCoordinatorView(coordinator: .init(parent: coordinator))
        case .home:
            HomeCoordinatorView(coordinator: .init(parent: coordinator, modelContext: modelContext))
        case .none:
            EmptyView()
        }
    }
}
