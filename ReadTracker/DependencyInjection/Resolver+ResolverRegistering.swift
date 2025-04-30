import Resolver

extension Resolver: @retroactive ResolverRegistering {
    public static func registerAllServices() {
        registerServices()
        registerRepositories()
        registerScenes()
    }
}
