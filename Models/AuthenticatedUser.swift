protocol AuthenticatedUser {
    var uid: String { get }
    var email: String? { get }
    var displayName: String? { get }
}
