import Resolver

extension Resolver {
    static func registerServices() {
        // USER
        Resolver.register { DefaultAuthenticationService() }
            .implements(AuthenticationService.self)
        Resolver.register { DefaultUsersFirestoreService() }
            .implements(UsersFirestoreService.self)
        Resolver.register { DefaultLocalUsersService() }
            .implements(LocalUsersService.self)

        // BOOKS
        Resolver.register { DefaultBookDownloadService() }
            .implements(BookDownloadService.self)
        Resolver.register { DefaultBookFirestoreService() }
            .implements(BookFirestoreService.self)
        register { BookStorageService() }
            .implements(BookStorageServiceProtocol.self)
            .scope(.application)
        Resolver.register { BookSyncService() }
    }
}
