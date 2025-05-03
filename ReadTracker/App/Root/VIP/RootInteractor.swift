import Combine
import Resolver
import SwiftData
import SwiftUI

final class DefaultRootInteractor {
    private weak var coordinator: DefaultRootCoordinator?

    private static var didPerformBookSync = false
    private static let syncLock = NSLock()

    private let modelContext: ModelContext

    init(
        coordinator: DefaultRootCoordinator,
        modelContext: ModelContext
    ) {
        self.coordinator = coordinator
        self.modelContext = modelContext
    }
}

// MARK: - Business Logic

extension DefaultRootInteractor {
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

//    func tapLogin() {
//        coordinator?.navigateToLogin()
//    }
//
//    func tapRegister() {
//        coordinator?.navigateToRegister()
//    }

    // MARK: - View Did Change

    func viewDidChange(_ type: ViewDidChangeType) {
        switch type {
        case .onAppear:
            performFullBookSync()

        case .onDisappear: break
        } 
    }
}
