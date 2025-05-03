import FirebaseAuth
import Resolver
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var user: User?

    var body: some View {
        ZStack {
            if let user {
                HomeCoordinatorView(coordinator: .init(parent: nil, modelContext: modelContext))
            } else {
                AuthenticationCoordinatorView(coordinator: .init(modelContext: modelContext))
            }
            LoadingIndicator(
                animation: .text,
                color: .black,
                size: .extraLarge,
                speed: .normal
            )
        }
        .onAppear(perform: onAppear)
    }

    func onAppear() {
        user = FirebaseAuth.Auth.auth().currentUser
        Resolver.register { modelContext }
    }
}
