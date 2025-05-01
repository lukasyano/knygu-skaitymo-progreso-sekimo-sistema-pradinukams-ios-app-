import Combine
import Resolver

protocol BookRepository {
    func fetchBooks() -> AnyPublisher<[Book], Error>
}

class DefaultBookRepository {
    private let authenticationService: AuthenticationService
    private let userService: UserService
    private let bookService: BookFirestoreService

    init(
        authenticationService: AuthenticationService = Resolver.resolve(),
        userService: UserService = Resolver.resolve(),
        bookService: BookFirestoreService = Resolver.resolve()
    ) {
        self.authenticationService = authenticationService
        self.userService = userService
        self.bookService = bookService
    }
}

extension DefaultBookRepository: BookRepository {
    func fetchBooks() -> AnyPublisher<[Book], Error> {
        guard let userId = authenticationService.getCurrentUser()?.uid else { return .empty() }

        return userService.getUserRole(userID: userId)
            .flatMap { [weak self] userRole -> AnyPublisher<[Book], Error> in
                guard let self, let userRole else { return .empty() }

                return bookService.fetchBooks(for: userRole)
            }
            .eraseToAnyPublisher()
    }
}
