import Resolver
extension Resolver {
    static func registerRepositories() {
        Resolver.register { DefaultUserRepository() }
            .implements(UserRepository.self)

        Resolver.register { DefaultBookRepository() }
            .implements(BookRepository.self)
    }
}
