import Combine
import Foundation
import Resolver
import SwiftData

protocol BookRepository {
    func refreshBooks() -> AnyPublisher<Void, Error>
    func refreshIfNeeded() -> AnyPublisher<Void, Error>
}

final class DefaultBookRepository: BookRepository {
     private var firestoreService: BookFirestoreService
     private var syncService: BookSyncService
     private var downloadService: BookDownloadService
     private var modelContext: ModelContext
     private var storage: BookStorageServiceProtocol
    
    init(
        firestoreService: BookFirestoreService = Resolver.resolve(),
        syncService: BookSyncService = Resolver.resolve(),
        downloadService: BookDownloadService = Resolver.resolve(),
        modelContext: ModelContext = Resolver.resolve(),
        storage: BookStorageServiceProtocol = Resolver.resolve()
    ) {
        self.firestoreService = firestoreService
        self.syncService = syncService
        self.downloadService = downloadService
        self.modelContext = modelContext
        self.storage = storage
    }

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
