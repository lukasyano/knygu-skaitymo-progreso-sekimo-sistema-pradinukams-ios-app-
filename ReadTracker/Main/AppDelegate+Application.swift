import FirebaseAuth
import FirebaseCore
import FirebaseDatabase
import UIKit

extension AppDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        let ref = Database.database().reference()

        ref.child("users").child("user-id").setValue(["username": "testUser"])

        ref.child("users").child("user-id").observeSingleEvent(of: .value) {
            let value = $0.value as? NSDictionary
            let username = value?["username"] as? String ?? "Anonymous"
            print("Hello, \(username)!")
        }

        Auth.auth().createUser(withEmail: "test@example.com", password: "password") { _, error in
            if let error = error {
                print("Registration error: \(error.localizedDescription)")
            } else {
                print("User registered successfully!")
            }
        }

        Auth.auth().signIn(withEmail: "test@example.com", password: "password") { _, error in
            if let error = error {
                print("Login error: \(error.localizedDescription)")
            } else {
                print("User logged in successfully!")
            }
        }

        // try! Auth.auth().signOut()

        return true
    }
}
