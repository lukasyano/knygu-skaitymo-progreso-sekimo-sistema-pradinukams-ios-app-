import Combine
import Resolver
import SwiftData
import SwiftUI

protocol RootInteractor: AnyObject {
    func onAppDidBecomeActive()
}

final class DefaultRootInteractor {
    private weak var coordinator: DefaultRootCoordinator?

    private static var didPerformBookSync = false
    private static let syncLock = NSLock()

    private let modelContext: ModelContext
    private let auhenticationService: AuthenticationService

    init(
        coordinator: DefaultRootCoordinator = Resolver.resolve(),
        modelContext: ModelContext,
        authenticationService: AuthenticationService = Resolver.resolve()
    ) {
        self.coordinator = coordinator
        self.modelContext = modelContext
        self.auhenticationService = authenticationService
    }
}

// MARK: - Business Logic

extension DefaultRootInteractor: RootInteractor {
    func onAppDidBecomeActive() {
        performFullBookSync()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let user = self.auhenticationService.getCurrentUser() {
                self.coordinator?.navigateToHome(userID: user.uid)
            }
            self.coordinator?.navigateToAuthentication()
        }
    }

    private func performFullBookSync() {
        Self.syncLock.lock()
        defer { Self.syncLock.unlock() }

        guard !Self.didPerformBookSync else {
            print("🔁 Skipping sync — already performed this session.")
            return
        }

        Self.didPerformBookSync = true
        print("📚 Performing initial full book sync...")

        let syncService = BookSyncService(modelContext: modelContext)
        let downloadService = DefaultBookDownloadService(modelContext: modelContext)

        syncService.syncBooks { newBooks in
            downloadService.downloadBooksIfNeeded(newBooks)
        }
    }
}
