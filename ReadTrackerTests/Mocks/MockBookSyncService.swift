//
//  MockBookSyncService.swift
//  ReadTracker
//
//  Created by Lukas Toliušis   on 02/06/2025.
//

import Combine
import Foundation
@testable import ReadTracker

class MockBookSyncService: BookSyncService {
    // Mock return values
    var mockFetchFromGitHubAndAddToFirestore: AnyPublisher<Void, Error> = .just(())
    var mockSyncFirestoreToSwiftData: AnyPublisher<Void, Error> = .just(())

    // Call tracking closures
    var fetchFromGitHubAndAddToFirestoreCall: VoidClosure?
    var syncFirestoreToSwiftDataCall: VoidClosure?

    // MARK: - BookSyncService Implementation

    func fetchFromGitHubAndAddToFirestore() -> AnyPublisher<Void, Error> {
        defer { fetchFromGitHubAndAddToFirestoreCall?() }
        return mockFetchFromGitHubAndAddToFirestore
    }

    func syncFirestoreToSwiftData() -> AnyPublisher<Void, Error> {
        defer { syncFirestoreToSwiftDataCall?() }
        return mockSyncFirestoreToSwiftData
    }
}
