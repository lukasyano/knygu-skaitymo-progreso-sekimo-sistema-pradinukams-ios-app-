//
//  MockBookStorageService.swift
//  ReadTracker
//
//  Created by Lukas Toliušis   on 02/06/2025.
//

@testable import ReadTracker

class MockBookStorageService: BookStorageServiceProtocol {
    // MARK: - shouldRefresh
    var mockShouldRefresh: Bool = false
    var shouldRefreshCallCount = 0

    var shouldRefresh: Bool {
        shouldRefreshCallCount += 1
        return mockShouldRefresh
    }

    // MARK: - markLastRefresh
    var markLastRefreshCalled = false
    var markLastRefreshCall: Closure<Void>?

    func markLastRefresh() {
        markLastRefreshCalled = true
        markLastRefreshCall?(())
    }
}
