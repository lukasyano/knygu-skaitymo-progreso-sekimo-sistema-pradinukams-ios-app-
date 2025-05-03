import SwiftUI

struct RootCoordinatorView: View {
    @ObservedObject var coordinator: DefaultRootCoordinator
    @Environment(\.modelContext) private var modelContext

    init(coordinator: DefaultRootCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        contentView
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch coordinator.route {
        case .splash:
            EmptyView()
        case .carousel: EmptyView()
           /// LottieAnimationView(animation: .named("StarAnimation"))
//                .configure { lottieAnimationView in
//                    lottieAnimationView.loopMode = .loop
//                }
                //.playing()
                //.frame(width: 200, height: 200)
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

