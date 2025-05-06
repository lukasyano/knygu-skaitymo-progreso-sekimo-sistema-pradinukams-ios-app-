import Combine
import Foundation
import Resolver
import SwiftData

protocol BookRepository {
    /// Fetches books appropriate for the current user:
    /// 1. Fetches from Firestore based on role
    /// 2. Syncs Firestore data into local SwiftData entities
    /// 3. Triggers PDF downloads if needed
    func fetchBooks() -> AnyPublisher<[BookEntity], Error>
}

class DefaultBookRepository {
    private let authService: AuthenticationService
    private let usersService: UsersFirestoreService
    private let firestoreService: BookFirestoreService
    private let syncService: BookSyncService
    private let downloadService: BookDownloadService
    private let modelContext: ModelContext

    init(
        authService: AuthenticationService = Resolver.resolve(),
        usersService: UsersFirestoreService = Resolver.resolve(),
        firestoreService: BookFirestoreService = Resolver.resolve(),
        syncService: BookSyncService = Resolver.resolve(),
        downloadService: BookDownloadService = Resolver.resolve(),
        modelContext: ModelContext = Resolver.resolve()
    ) {
        self.authService = authService
        self.usersService = usersService
        self.firestoreService = firestoreService
        self.syncService = syncService
        self.downloadService = downloadService
        self.modelContext = modelContext
    }
}

extension DefaultBookRepository: BookRepository {
    
    
    
    func fetchBooks() -> AnyPublisher<[BookEntity], Error> {
        guard let userID = authService.getUserID() else { return .empty() }

        // Step 1: Fetch role
        return usersService.getUserRole(userID: userID)
            .flatMap { [weak self] role -> AnyPublisher<[Book], Error> in
                guard let role else {
                    return .fail(NSError(domain: "NoRole", code: -1))
                }
                // Step 2: Fetch remote books
                return self?.firestoreService.fetchBooks(for: role) ?? .empty()
            }
            // Step 3: Sync remote list into local SwiftData
            .flatMap { [weak self] _ -> AnyPublisher<[BookEntity], Error> in
                return self?.syncService.syncBooks() ?? .empty()
            }
            .flatMap { _ -> AnyPublisher<[BookEntity], Error> in
                return self.downloadService.downloadBooks()
                    .map { results in results.map { $0.entity } }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
//    private func fetchLocalBooks() -> AnyPublisher<[BookEntity], Error> {
//        guard let userID = authService.getUserID() else { return .empty() }
//        
//        
//        
//    }
    
}
