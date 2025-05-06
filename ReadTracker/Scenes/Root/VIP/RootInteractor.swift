import Combine
import Foundation
import Resolver
import SwiftData

protocol RootInteractor: AnyObject {
    func onAppear()
}

final class DefaultRootInteractor {
    private weak var coordinator: DefaultRootCoordinator?
    private static let syncLock = NSLock()

    private let storageService: BookStorageService
    private let authenticationService: AuthenticationService
    private let modelContext: ModelContext

    // Combine bag
    private var cancelBag = Set<AnyCancellable>()

    init(
        coordinator: DefaultRootCoordinator = Resolver.resolve(),
        modelContext: ModelContext = Resolver.resolve(),
        storageService: BookStorageService = DefaultBookStorageService(),
        authenticationService: AuthenticationService = Resolver.resolve()
    ) {
        self.coordinator = coordinator
        self.modelContext = modelContext
        self.storageService = storageService
        self.authenticationService = authenticationService
    }
}

// MARK: - Business Logic

extension DefaultRootInteractor: RootInteractor {
    func onAppear() {
        performFullBookSyncIfNeeded()
        checkForAuthentication()
    }

    private func checkForAuthentication() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let userId = self.authenticationService.getUserID() {
                self.coordinator?.navigateToHome(userID: userId)
            } else {
                self.coordinator?.navigateToAuthentication()
            }
        }
    }

    private func performFullBookSyncIfNeeded() {
        Self.syncLock.lock(); defer { Self.syncLock.unlock() }

        guard storageService.shouldPerformFullSync() else {
            print("🔁 Skipping sync — next sync in <24h.")
            return
        }

        storageService.markFullSyncPerformed()
        print("📚 Performing full book sync...")

        let syncService = BookSyncService(modelContext: modelContext)
        let downloadService = DefaultBookDownloadService(modelContext: modelContext)

        syncService.syncBooks()
            .flatMap { _ in
                downloadService.downloadBooks()
            }
            .sink(
                receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Sync error: \(error)")
                }
            }, receiveValue: { results in
                print("Downloaded \(results.count) books.")
            })
            .store(in: &cancelBag)
    }
}
