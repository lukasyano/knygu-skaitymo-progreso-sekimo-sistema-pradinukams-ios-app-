import Foundation

protocol BookStorageServiceProtocol {
    var shouldRefresh: Bool { get }
    func markLastRefresh()
}

struct BookStorageService: BookStorageServiceProtocol {
    private let userDefaults: UserDefaults
    private let lastRefreshKey = "lastBookRefresh"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var shouldRefresh: Bool {
        guard let lastDate = userDefaults.object(forKey: lastRefreshKey) as? Date else { return true }
        return Date().timeIntervalSince(lastDate) > 86400
    }

    func markLastRefresh() {
        userDefaults.set(Date(), forKey: lastRefreshKey)
    }
}
