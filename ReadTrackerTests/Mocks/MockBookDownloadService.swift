//
//  MockBookDownloadService.swift
//  ReadTracker
//
//  Created by Lukas Toliušis   on 02/06/2025.
//

import Combine
@testable import ReadTracker

class MockBookDownloadService: BookDownloadService {
    // MARK: - downloadMissingBooks
    var mockDownloadMissingBooks: AnyPublisher<Void, Error> = Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    var downloadMissingBooksCallCount = 0

    func downloadMissingBooks() -> AnyPublisher<Void, Error> {
        downloadMissingBooksCallCount += 1
        return mockDownloadMissingBooks
    }

    // MARK: - clearLocalFiles
    var mockClearLocalFiles: AnyPublisher<Void, Error> = Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    var clearLocalFilesCallCount = 0

    func clearLocalFiles() -> AnyPublisher<Void, Error> {
        clearLocalFilesCallCount += 1
        return mockClearLocalFiles
    }
}
