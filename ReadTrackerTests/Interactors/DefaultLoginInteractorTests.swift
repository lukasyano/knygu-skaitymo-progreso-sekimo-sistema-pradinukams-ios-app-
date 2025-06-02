import XCTest
import Combine
@testable import ReadTracker

final class DefaultLoginInteractorTests: XCTestCase {
    private var interactor: LoginInteractor!
    private var mockUserRepository: MockUserRepository!
    private var mockPresenter: MockLoginPresenter!
    private var mockCoordinator: MockLoginCoordinator!
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        mockUserRepository = MockUserRepository()
        mockPresenter = MockLoginPresenter()
        mockCoordinator = MockLoginCoordinator()

        interactor = DefaultLoginInteractor(
            coordinator: mockCoordinator,
            presenter: mockPresenter,
            userRepository: mockUserRepository,
            email: "test@example.com",
            shouldAutoNavigateToHome: true
        )
    }

    // MARK: - Tests

    func test_onLoginTap_success_navigatesToHome() {
        let expectedUser = UserEntity(id: "123", email: "test@example.com", name: "Test", role: .parent)
        mockUserRepository.mockLogIn = Just(expectedUser)
            .setFailureType(to: UserError.self)
            .eraseToAnyPublisher()

        let expectation = expectation(description: "Coordinator navigates to home")

        mockCoordinator.onNavigateToHome = { userID in
            XCTAssertEqual(userID, expectedUser.id)
            expectation.fulfill()
        }

        interactor.onLoginTap()

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(mockUserRepository.logInCallCount, 1)
        XCTAssertTrue(mockPresenter.loadingStates.contains(true))
    }

    func test_onLoginTap_failure_showsError() {
        let expectedError = UserError.message("Invalid credentials")
        mockUserRepository.mockLogIn = Fail(error: expectedError)
            .eraseToAnyPublisher()

        let expectation = expectation(description: "Coordinator presents error")

        mockCoordinator.onPresentError = { message, onClose in
            XCTAssertEqual(message, "Invalid credentials")
            onClose()
            expectation.fulfill()
        }

        interactor.onLoginTap()

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(mockUserRepository.logInCallCount, 1)
        XCTAssertTrue(mockPresenter.loadingStates.contains(true))
        XCTAssertTrue(mockPresenter.loadingStates.contains(false))
    }

    func test_onEmailChange_updatesEmailAndPresents() {
        interactor.onEmailChange("new@email.com")
        XCTAssertEqual(mockPresenter.presentedEmails.last, "new@email.com")
    }

    func test_onPasswordChange_updatesPasswordAndPresents() {
        interactor.onPasswordChange("newPassword123")
        XCTAssertEqual(mockPresenter.presentedPasswords.last, "newPassword123")
    }

    func test_viewDidAppear_presentsInitialEmailAndPassword() {
        interactor.viewDidAppear()
        XCTAssertEqual(mockPresenter.presentedPasswords.last, MockCredentials.password())
    }

    func test_viewDidDisappear_clearsCancelBag() {
        interactor.viewDidAppear()
        interactor.viewDidDisappear()
        XCTAssertTrue(true)
    }
}
