import Combine
import Resolver
import SwiftData
import SwiftUI

// MARK: - Storage Service

protocol BookStorageService {
    var lastFullSyncDate: Date? { get }
    func shouldPerformFullSync() -> Bool
    func markFullSyncPerformed()
}

final class DefaultBookStorageService: BookStorageService {
    private let defaults = UserDefaults.standard
    private static let lastSyncKey = "DefaultRootInteractor.lastFullSyncDate"

    var lastFullSyncDate: Date? {
        defaults.object(forKey: Self.lastSyncKey) as? Date
    }

    func shouldPerformFullSync() -> Bool {
        guard let last = lastFullSyncDate else {
            return true 
        }
        return Date().timeIntervalSince(last) >= 24 * 60 * 60
    }

    func markFullSyncPerformed() {
        defaults.set(Date(), forKey: Self.lastSyncKey)
    }
}

// MARK: - Interactor

protocol RootInteractor: AnyObject {
    func onAppear()
}

final class DefaultRootInteractor {
    private weak var coordinator: DefaultRootCoordinator?
    private static let syncLock = NSLock()

    private let storageService: BookStorageService
    private let authenticationService: AuthenticationService
    private let modelContext: ModelContext

    init(
        coordinator: DefaultRootCoordinator = Resolver.resolve(),
        modelContext: ModelContext,
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
        Self.syncLock.lock()
        defer { Self.syncLock.unlock() }

        guard storageService.shouldPerformFullSync() else {
            print("🔁 Skipping sync — next sync in <24h.")
            return
        }

        storageService.markFullSyncPerformed()
        print("📚 Performing full book sync...")

        let syncService = BookSyncService(modelContext: modelContext)
        let downloadService = DefaultBookDownloadService(modelContext: modelContext)

        syncService.syncBooks { _ in
            downloadService.downloadBooks(force: false)
        }
    }
}
