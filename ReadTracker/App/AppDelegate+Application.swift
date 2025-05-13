import FirebaseCore
import FirebaseAuth
import UIKit

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
