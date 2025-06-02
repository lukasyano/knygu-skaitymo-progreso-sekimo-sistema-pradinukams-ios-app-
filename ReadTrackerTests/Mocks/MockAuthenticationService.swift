//
//  MockAuthenticationService.swift
//  ReadTracker
//
//  Created by Lukas Toliušis on 02/06/2025.
//

import Combine
import Foundation
@testable import ReadTracker

// MARK: - Protocol for Abstracting FirebaseAuth.User

// MARK: - Mock User

struct MockUser: AuthenticatedUser {
    var uid: String = "mockUID123"
    var email: String? = "mock@example.com"
    var displayName: String? = "Mock User"
}

// MARK: - Mock Authentication Service

class MockAuthenticationService: AuthenticationService {
    // MARK: - createUser

    var mockCreateUser: AnyPublisher<AuthenticatedUser, UserError> =
        .just(MockUser())

    var createUserCall: Closure<(String, String)>?

    func createUser(email: String, password: String) -> AnyPublisher<AuthenticatedUser, UserError> {
        defer { createUserCall?((email, password)) }
        return mockCreateUser
    }

    // MARK: - signIn

    var mockSignIn: AnyPublisher<AuthenticatedUser, UserError> =
        Just(MockUser())
        .setFailureType(to: UserError.self)
        .eraseToAnyPublisher()

    var signInCall: Closure<(String, String)>?

    func signIn(email: String, password: String) -> AnyPublisher<AuthenticatedUser, UserError> {
        defer { signInCall?((email, password)) }
        return mockSignIn
    }

    // MARK: - signOut

    var signOutCalled = false
    var signOutError: Error?

    func signOut() throws {
        signOutCalled = true
        if let error = signOutError {
            throw error
        }
    }

    // MARK: - authStatePublisher

    var mockAuthStateSubject = CurrentValueSubject<String?, Never>(nil)

    var authStatePublisher: AnyPublisher<String?, Never> {
        mockAuthStateSubject.eraseToAnyPublisher()
    }
}
