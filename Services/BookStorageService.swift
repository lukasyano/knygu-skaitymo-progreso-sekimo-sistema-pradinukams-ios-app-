import Foundation

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
        guard let last = lastFullSyncDate else { return true }
        return Date().timeIntervalSince(last) >= 24 * 60 * 60
    }

    func markFullSyncPerformed() {
        defaults.set(Date(), forKey: Self.lastSyncKey)
    }
}
