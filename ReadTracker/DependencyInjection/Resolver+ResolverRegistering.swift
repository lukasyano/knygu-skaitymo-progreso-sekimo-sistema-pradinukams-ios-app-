import Resolver

extension Resolver: @retroactive ResolverRegistering {
    public static func registerAllServices() {
        // for swiftData model context
        register { DataConfiguration.shared.context }
            .scope(.application)

        Resolver.register { DefaultRootCoordinator() }
            .scope(.shared)
        Resolver.register { DefaultRootInteractor() }
            .implements(RootInteractor.self)
            .scope(.shared)

        register { DefaultUserStorageService() }
            .implements(UserStorageService.self)

        // do not delete it will reinitialize navigation stack
        Resolver.register { DefaultAuthenticationCoordinator() }
            .scope(.shared)

        registerServices()
        registerRepositories()
    }
}
