import Combine
import Foundation
import Resolver
import SwiftData

protocol BookRepository {
    func refreshBooks() -> AnyPublisher<Void, Error>
    func refreshIfNeeded() -> AnyPublisher<Void, Error>
}

final class DefaultBookRepository: BookRepository {
    @Injected private var authService: AuthenticationService
    @Injected private var usersService: UsersFirestoreService
    @Injected private var firestoreService: BookFirestoreService
    @Injected private var syncService: BookSyncService
    @Injected private var downloadService: BookDownloadService
    @Injected private var modelContext: ModelContext
    @Injected private var storage: BookStorageService

    private let backgroundQueue = DispatchQueue(label: "com.youapp.book-repository", qos: .userInitiated)

    func refreshBooks() -> AnyPublisher<Void, Error> {
        clearBooks()
            .flatMap { _ in self.populateBooks() }
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case let .failure(error) = completion {
                        print("Refresh failed: \(error)")
                    } else {
                        storage.markLastRefresh()
                    }
                }
            )
            .eraseToAnyPublisher()
    }

    private func clearBooks() -> AnyPublisher<Void, Error> {
        Publishers.Zip3(
            deleteFirestoreBooks(),
            downloadService.clearLocalFiles(),
            deleteSwiftDataBooks(),
        )
        .subscribe(on: backgroundQueue)
        .receive(on: DispatchQueue.main)
        .mapToVoid()
        .eraseToAnyPublisher()
    }

    func populateBooks() -> AnyPublisher<Void, Error> {
        syncService.fetchFromGitHubAndAddToFirestore()
            .subscribe(on: backgroundQueue)
            .flatMap { [weak self] in self?.syncService.syncFirestoreToSwiftData() ?? .empty() }
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] in self?.downloadService.downloadMissingBooks() ?? .empty() }
            .subscribe(on: backgroundQueue)
            .receive(on: DispatchQueue.main)
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func refreshIfNeeded() -> AnyPublisher<Void, Error> {
        guard storage.shouldRefresh else { return .just(()) }
        return refreshBooks()
    }

    // MARK: - Private Helpers
    private func deleteFirestoreBooks() -> AnyPublisher<Void, Error> {
        firestoreService.deleteAllBooks()
    }

    private func deleteSwiftDataBooks() -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let context = self?.modelContext else {
                return promise(.failure(NSError(domain: "Context", code: -1)))
            }
            do {
                try context.delete(model: BookEntity.self)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}
