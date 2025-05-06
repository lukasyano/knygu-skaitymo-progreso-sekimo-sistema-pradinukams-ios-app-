enum MockCredentials {
    static func email(index: Int = 0) -> String {
        "test\(index)@example.com"
    }

    static var name: String {
        "Test User"
    }

    static func password() -> String {
        "password"
    }
}
