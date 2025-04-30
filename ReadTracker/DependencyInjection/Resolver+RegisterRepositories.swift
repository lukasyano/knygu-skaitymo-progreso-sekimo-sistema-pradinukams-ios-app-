import Resolver

extension Resolver {
    static func registerRepositories() {
        Resolver.register { DefaultAuthenticationRepository() }
            .implements(AuthenticationRepository.self)
    }
}
