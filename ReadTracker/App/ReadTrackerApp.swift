import Resolver
import SwiftData
import SwiftUI

// extension UIViewController {
//    public override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Atgal", style: .plain, target: nil, action: nil)
//    }
// }

@main
struct ReadTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([Item.self])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
//    init() {
//        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Atgal", style: .plain, target: nil, action: nil)
//    }

    var body: some Scene {
        WindowGroup {
            AuthenticationCoordinatorView(coordinator: .init())
        }
        //  .modelContainer(sharedModelContainer)
    }
}
