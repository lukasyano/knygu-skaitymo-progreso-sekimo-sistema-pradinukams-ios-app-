import FirebaseAuth

enum UserMapper {
    static func mapFromUserToUserEntity(_ user: User, name: String, role: Role) -> UserEntity {
        .init(
            id: user.uid,
            email: user.email ?? "email@example.com",
            name: name,
            role: role
        )
    }
}
