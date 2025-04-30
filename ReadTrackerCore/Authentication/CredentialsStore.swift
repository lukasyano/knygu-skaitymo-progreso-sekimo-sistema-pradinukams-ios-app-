import Foundation

public protocol CredentialsStore {
    var savedEmail: String? { get set }
    var rememberUser: Bool { get set }
    func clear()
}

public final class DefaultCredentialsStore: CredentialsStore {
    public init() {}

    private enum Keys {
        static let savedEmail = "credentials.email"
        static let rememberUser = "credentials.remember"
    }

    public var savedEmail: String? {
        get { UserDefaults.standard.string(forKey: Keys.savedEmail) }
        set { UserDefaults.standard.setValue(newValue, forKey: Keys.savedEmail) }
    }

    public var rememberUser: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.rememberUser) }
        set { UserDefaults.standard.setValue(newValue, forKey: Keys.rememberUser) }
    }

    public func clear() {
        UserDefaults.standard.removeObject(forKey: Keys.savedEmail)
        UserDefaults.standard.removeObject(forKey: Keys.rememberUser)
    }
}
