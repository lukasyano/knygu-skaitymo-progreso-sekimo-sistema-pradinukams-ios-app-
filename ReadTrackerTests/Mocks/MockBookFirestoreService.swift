import Combine
import Foundation

@testable import ReadTracker

class MockBookFirestoreService: BookFirestoreService {
    // Mock return values
    var mockFetchAllBooks: AnyPublisher<[Book], Error> = .just([])
    var mockAddBooks: AnyPublisher<Void, Error> = .just(())
    var mockDeleteAllBooks: AnyPublisher<Void, Error> = .just(())

    // Call tracking closures
    var fetchAllBooksCall: VoidClosure?
    var addBooksCall: Closure<[Book]>?
    var deleteAllBooksCall: VoidClosure?

    // MARK: - BookFirestoreService Implementation

    func fetchAllBooks() -> AnyPublisher<[Book], Error> {
        defer { fetchAllBooksCall?() }
        return mockFetchAllBooks
    }

    func addBooks(_ books: [Book]) -> AnyPublisher<Void, Error> {
        defer { addBooksCall?(books) }
        return mockAddBooks
    }

    func deleteAllBooks() -> AnyPublisher<Void, Error> {
        defer { deleteAllBooksCall?() }
        return mockDeleteAllBooks
    }
}
