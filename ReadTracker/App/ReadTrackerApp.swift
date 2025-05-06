import Resolver
import SwiftData
import SwiftUI

@main
struct ReadTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        _ = DataConfiguration.shared
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootCoordinatorView(
                    coordinator: Resolver.resolve(),
                    interactor: Resolver.resolve()
                )
            }
        }
        .modelContainer(for: BookEntity.self)
    }
}
