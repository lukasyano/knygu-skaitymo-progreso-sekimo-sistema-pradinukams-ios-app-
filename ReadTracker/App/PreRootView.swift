import Resolver
import SwiftData
import SwiftUI

struct PreRootView: View {
    @Environment(\.modelContext) var modelContext: ModelContext

    var body: some View {
        RootCoordinatorView(
            coordinator: Resolver.resolve(),
            interactor: .init(modelContext: modelContext)
        )
    }
}

#Preview {
    PreRootView()
}
