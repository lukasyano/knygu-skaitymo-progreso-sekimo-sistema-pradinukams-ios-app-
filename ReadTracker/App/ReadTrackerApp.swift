import Resolver
import SwiftData
import SwiftUI

@main
struct ReadTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    let container = DataConfiguration.shared.container

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootCoordinatorView(
                    coordinator: Resolver.resolve(),
                    interactor: Resolver.resolve()
                )
            }
        }
        .modelContainer(container)
    }
}
