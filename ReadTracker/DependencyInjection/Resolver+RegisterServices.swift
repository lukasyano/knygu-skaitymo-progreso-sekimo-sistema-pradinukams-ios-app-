import Resolver

extension Resolver {
    static func registerServices() {
        Resolver.register { DefaultCredentialsStore() }
            .implements(CredentialsStore.self)
        Resolver.register { DefaultFirebaseAuthService() }
            .implements(FirebaseAuthService.self)
        Resolver.register { DefaultUserProfileService() }
            .implements(UserProfileService.self)
    }
}
