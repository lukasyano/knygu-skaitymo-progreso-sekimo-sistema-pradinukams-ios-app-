@testable import ReadTracker
import Foundation

//
//  MockLoginCoordinator.swift
//  ReadTracker
//
//  Created by Lukas Toliušis   on 02/06/2025.
//

final class MockLoginCoordinator: LoginCoordinator {
    var onNavigateToHome: ((String) -> Void)?
    var onPresentError: ((String, () -> Void) -> Void)?

    func navigateToHome(userID: String) {
        navigateToHomeCallCount += 1
        lastNavigatedUserID = userID
        onNavigateToHome?(userID)
    }

    func presentError(_ message: String, onClose: @escaping () -> Void) {
        presentErrorCallCount += 1
        lastErrorMessage = message
        onCloseCallback = onClose
        onPresentError?(message, onClose)
    }

    func presentLoginComplete(_ message: String, onClose: @escaping () -> Void) {}

    // MARK: - Coordinator Conformance
    var parent: (any Coordinator)?
    var presentedView: MockPresentedView?
    var route: MockRoute?

    struct MockPresentedView: Identifiable {
        let id = UUID()
    }

    enum MockRoute {
        case dummy
    }

    // Tracking calls
    var navigateToHomeCallCount = 0
    var lastNavigatedUserID: String?

    var presentErrorCallCount = 0
    var lastErrorMessage: String?
    var onCloseCallback: (() -> Void)?

}
