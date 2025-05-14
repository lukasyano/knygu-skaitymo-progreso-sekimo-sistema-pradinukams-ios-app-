import FirebaseCore
import UIKit
import FirebaseAuth

extension AppDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        
        try? Auth.auth().signOut()

        return true
    }
}
