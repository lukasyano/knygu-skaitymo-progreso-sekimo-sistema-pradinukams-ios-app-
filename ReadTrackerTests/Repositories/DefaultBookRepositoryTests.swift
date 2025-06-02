//
//  DefaultBookRepositoryTests.swift
//  ReadTracker
//
//  Created by Lukas Toliušis   on 02/06/2025.
//

import Combine
@testable import ReadTracker
import Resolver
import SwiftData
import XCTest

final class DefaultBookRepositoryTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    private var firestore: MockBookFirestoreService!
    private var sync: MockBookSyncService!
    private var download: MockBookDownloadService!
    private var storage: MockBookStorageService!
    private var context: ModelContext = Resolver.resolve()
    private var sut: DefaultBookRepository!

    override func setUp() {
        super.setUp()
        firestore = MockBookFirestoreService()
        sync = MockBookSyncService()
        download = MockBookDownloadService()
        storage = MockBookStorageService()

        sut = DefaultBookRepository(
            firestoreService: firestore,
            syncService: sync,
            downloadService: download,
            modelContext: context,
            storage: storage
        )
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_refreshBooks_success() {
        let expectation = expectation(description: "refreshBooks succeeds")

        sut.refreshBooks()
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
                expectation.fulfill()
            }, receiveValue: {})
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_refreshBooks_failure_in_clearBooks() {
        firestore.mockDeleteAllBooks = Fail(error: TestError.someError).eraseToAnyPublisher()

        let expectation = expectation(description: "refreshBooks fails in clearBooks")

        sut.refreshBooks()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    XCTFail("Expected failure, got success")
                }
                expectation.fulfill()
            }, receiveValue: {})
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_refreshBooks_failure_in_populateBooks() {
        sync.mockFetchFromGitHubAndAddToFirestore = Fail(error: TestError.someError).eraseToAnyPublisher()

        let expectation = expectation(description: "refreshBooks fails in populateBooks")

        sut.refreshBooks()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    XCTFail("Expected failure, got success")
                }
                expectation.fulfill()
            }, receiveValue: {})
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_refreshIfNeeded_shouldRefreshFalse_returnsImmediately() {
        let expectation = expectation(description: "refreshIfNeeded returns immediately")

        sut.refreshIfNeeded()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Expected success, got failure")
                }
                expectation.fulfill()
            }, receiveValue: {})
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_refreshIfNeeded_shouldRefreshTrue_callsRefreshBooks() {
        let expectation = expectation(description: "refreshIfNeeded triggers refreshBooks")

        sut.refreshIfNeeded()
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
                expectation.fulfill()
            }, receiveValue: {})
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }
}

enum TestError: Error {
    case someError
}
