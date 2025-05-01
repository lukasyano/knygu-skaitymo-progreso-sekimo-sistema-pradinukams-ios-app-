import Resolver

enum HomeDependencyInjection {
    static func register() {
        Resolver.register { DefaultBookThumbnailWorker() }
            .implements(BookThumbnailWorker.self)
    }
}
