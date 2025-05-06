import Resolver

extension Resolver {
    static func registerServices() {
        Resolver.register { DefaultAuthenticationService() }
            .implements(AuthenticationService.self)
        
        Resolver.register { DefaultUsersFirestoreService() }
            .implements(UsersFirestoreService.self)
        
        
        Resolver.register { DefaultBookFirestoreService() }
            .implements(BookFirestoreService.self)
        Resolver.register { BookSyncService() }
        Resolver.register { DefaultBookDownloadService() }
            .implements(BookDownloadService.self)
    }
}
