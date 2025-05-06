import Resolver

extension Resolver: @retroactive ResolverRegistering {
    public static func registerAllServices() {
        
        Resolver.register { DefaultRootCoordinator() }
            .scope(.shared)
        Resolver.register { DefaultAuthenticationCoordinator() }
            .scope(.shared)
//        Resolver.register { DefaultAuthenticationInteractor() }
//            .implements(AuthenticationInteractor.self)
//            .scope(.shared)

        registerScenes()
        registerServices()
        registerRepositories()
    }
}
