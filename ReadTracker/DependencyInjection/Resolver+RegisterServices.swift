import Resolver
extension Resolver {
    static func registerServices() {
        // USER
        Resolver.register { DefaultAuthenticationService() }
            .implements(AuthenticationService.self)
            .scope(.application)

        Resolver.register { DefaultUsersFirestoreService() }
            .implements(UsersFirestoreService.self)
            .scope(.application)

        // BOOKS
        Resolver.register { DefaultBookDownloadService() }
            .implements(BookDownloadService.self)
            .scope(.application)
        Resolver.register { DefaultBookFirestoreService() }
            .implements(BookFirestoreService.self)
            .scope(.application)
        register { BookStorageService() }
            .implements(BookStorageServiceProtocol.self)
            .scope(.application)
        Resolver.register { BookSyncService() }
    }
}
