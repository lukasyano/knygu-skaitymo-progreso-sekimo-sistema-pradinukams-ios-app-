import Resolver

extension Resolver {
    static func registerServices() {
        Resolver.register { DefaultCredentialsStore() }
            .implements(CredentialsStore.self)
        Resolver.register { DefaultAuthenticationService() }
            .implements(AuthenticationService.self)
        Resolver.register { DefaultUserProfileService() }
            .implements(UserService.self)
        Resolver.register { DefaultBookFirestoreService() }
            .implements(BookFirestoreService.self)
//        Resolver.register { DefaultBookDownloadService() }
//            .implements(BookDownloadService.self)
    }
}
