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
                .transition(.opacity)
                .onAppear { [weak interactor] in interactor?.onAppear() }
        }
        .animation(.bouncy, value: coordinator.route)
    }

    @ViewBuilder
    private var contentView: some View {
        switch coordinator.route {
        case .authentication:
            AuthenticationCoordinatorView(coordinator: .init(modelContext: modelContext))

        case .carousel:
            LoadingIndicator(animation: .text, size: .large)

        case .login:
            LoginCoordinatorView(coordinator: .init(parent: coordinator, email: .none, shouldAutoNavigateToHome: false))

        case .register:
            RegistrationCoordinatorView(coordinator: .init(parent: coordinator))

        case .home:
            LoginCoordinatorView(coordinator: .init(parent: coordinator, email: .none, shouldAutoNavigateToHome: true))

        case .none:
            EmptyView()
        }
    }
}
