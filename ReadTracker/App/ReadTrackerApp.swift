import Resolver
import SwiftData
import SwiftUI

@main
struct ReadTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PreRootView()
            }
        }
        .modelContainer(for: BookEntity.self)
    }
}
