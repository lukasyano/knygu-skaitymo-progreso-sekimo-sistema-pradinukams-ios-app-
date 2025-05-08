import Combine
import Foundation
import Resolver
import SwiftData

protocol BookRepository {
    func fetchBooks(for role: Role) -> AnyPublisher<[BookEntity], Error>
    func refreshBooks() -> AnyPublisher<Void, Error>
    func deleteAllBooks() -> AnyPublisher<Void, Error>
    func populateBooks() -> AnyPublisher<Void, Error>
    func refreshIfNeeded() -> AnyPublisher<Void, Error>
}

final class DefaultBookRepository: BookRepository {
    private let authService: AuthenticationService
    private let usersService: UsersFirestoreService
    private let firestoreService: BookFirestoreService
    private let syncService: BookSyncService
    private let downloadService: BookDownloadService
    private let modelContext: ModelContext
    private let storage: BookStorageService

    private let backgroundQueue = DispatchQueue(label: "com.youapp.book-repository", qos: .userInitiated)

    init(
        authService: AuthenticationService = Resolver.resolve(),
        usersService: UsersFirestoreService = Resolver.resolve(),
        firestoreService: BookFirestoreService = Resolver.resolve(),
        syncService: BookSyncService = Resolver.resolve(),
        downloadService: BookDownloadService = Resolver.resolve(),
        modelContext: ModelContext = Resolver.resolve(),
        storage: BookStorageService = Resolver.resolve()
    ) {
        self.authService = authService
        self.usersService = usersService
        self.firestoreService = firestoreService
        self.syncService = syncService
        self.downloadService = downloadService
        self.modelContext = modelContext
        self.storage = storage
    }

    func fetchBooks(for role: Role) -> AnyPublisher<[BookEntity], Error> {
        Future { [weak self] promise in
            guard let self else { return promise(.failure(NSError(domain: "Self", code: -1))) }

            let descriptor = FetchDescriptor<BookEntity>(
                predicate: #Predicate { $0.role == role.rawValue }
            )

            do {
                let books = try self.modelContext.fetch(descriptor)
                promise(.success(books))
            } catch {
                promise(.failure(error))
            }
        }
        .subscribe(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func refreshBooks() -> AnyPublisher<Void, Error> {
        deleteAllBooks()
            .flatMap { _ in self.populateBooks() }
            .handleEvents(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Refresh failed: \(error)")
                    }
                },
                receiveCancel: { print("Refresh cancelled") }
            )
            .eraseToAnyPublisher()
    }

    func deleteAllBooks() -> AnyPublisher<Void, Error> {
        Publishers.Zip3(
            deleteFirestoreBooks(),
            deleteLocalFiles(),
            deleteSwiftDataBooks()
        )
        .subscribe(on: backgroundQueue)
        .receive(on: DispatchQueue.main)
        .mapToVoid()
        .eraseToAnyPublisher()
    }

    func populateBooks() -> AnyPublisher<Void, Error> {
        syncService.fetchFromGitHubAndAddToFirestore()
            .subscribe(on: backgroundQueue) // Offload initial work
            .flatMap { _ in self.syncService.syncFirestoreToSwiftData() }
            .receive(on: DispatchQueue.main) // SwiftData needs main thread
            .flatMap { _ in self.downloadService.downloadMissingBooks() }
            .subscribe(on: backgroundQueue) // Offload downloads
            .receive(on: DispatchQueue.main) // Final UI update
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

    private func deleteLocalFiles() -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let service = self?.downloadService else {
                return promise(.failure(NSError(domain: "Service", code: -1)))
            }

            do {
                let files = try FileManager.default.contentsOfDirectory(at: service.booksDirectory,
                                                                        includingPropertiesForKeys: nil)
                for file in files {
                    try FileManager.default.removeItem(at: file)
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
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
