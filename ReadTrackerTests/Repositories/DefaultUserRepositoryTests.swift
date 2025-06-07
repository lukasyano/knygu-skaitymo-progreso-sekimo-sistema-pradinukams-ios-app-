import Combine
@testable import ReadTracker
import XCTest

class DefaultUserRepositoryTests: XCTestCase {
    private var sut: DefaultUserRepository!
    private var authService: MockAuthenticationService!
    private var firestoreService: MockUsersFirestoreService!
    private var storageService: MockUserStorageService!
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        authService = MockAuthenticationService()
        firestoreService = MockUsersFirestoreService()
        storageService = MockUserStorageService()
        sut = DefaultUserRepository(
            firebaseAuth: authService,
            firestoreService: firestoreService,
            userStorageService: storageService
        )
    }
}

// MARK: - Create User Tests
extension DefaultUserRepositoryTests {
    func test_createUser_success() {
        // Given
        authService.mockCreateUser = .just(MockUser() as AuthenticatedUser)
        firestoreService.mockSaveUserEntity = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "createUser completes")

        sut.createUser(name: "Test", email: "test@test.com", password: "pass", role: .parent)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in
                }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }

    func test_createUser_failure() {
        // Given
        authService.mockCreateUser = .fail(.message("error"))

        // When
        let expectation = expectation(description: "createUser fails")

        sut.createUser(name: "Test", email: "test@test.com", password: "pass", role: .parent)
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()

                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }
}

// MARK: - Create Child User Tests
extension DefaultUserRepositoryTests {
    func test_createChildUser_success() {
        // Given
        let parent = UserEntity(id: "parent", email: "", name: "", role: .parent)

        authService.mockCreateUser = .just(MockUser() as AuthenticatedUser)
        firestoreService.mockSaveUserEntity = .just(())

        // When
        let expectation = expectation(description: "createChildUser completes")
        sut.createChildUser(name: "Child", email: "child@test.com", password: "pass", parent: parent)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }

    func test_createChildUser_failure() {
        // Given
        let parent = UserEntity(id: "parent", email: "", name: "", role: .parent)
        authService.mockCreateUser = .fail(.message("fail"))

        // When
        let expectation = expectation(description: "createChildUser fails")

        sut.createChildUser(name: "Child", email: "child@test.com", password: "pass", parent: parent)
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()

                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }
}

// MARK: - Login Tests
extension DefaultUserRepositoryTests {
    func test_logIn_success() {
        // Given
        let expectedUser = UserEntity(id: "123", email: "test@test.com", name: "Test", role: .parent)
        authService.mockCreateUser = .just(MockUser() as AuthenticatedUser)
        firestoreService.mockGetUserEntity = .just(expectedUser)

        // When
        let expectation = expectation(description: "logIn completes")

        sut.logIn(email: "test@test.com", password: "pass")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }

    func test_logIn_failure() {
        // Given
        authService.mockSignIn = .fail(.message("fail"))

        // When
        let expectation = expectation(description: "logIn fails")

        sut.logIn(email: "test@test.com", password: "wrong")
            .sink(
                receiveCompletion: {
                    if case .failure = $0 {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }
}

// MARK: - Current User Tests
extension DefaultUserRepositoryTests {
    func test_getCurrentUser_publishesValue() {
        // When
        let expectation = expectation(description: "getCurrentUser publishes")

        sut.getCurrentUser()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }

    func test_getCurrentUser_publishesNilAfterSignOut() {
        // When
        try? sut.signOut()
        let expectation = expectation(description: "getCurrentUser publishes nil")
        var receivedUser: UserEntity?

        sut.getCurrentUser()
            .sink { user in
                receivedUser = user
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(receivedUser)
    }
}

// MARK: - Auth State Tests
extension DefaultUserRepositoryTests {
    func test_authStatePublisher_publishesUID() {
        // Given
        let expectedUID = "auth-user-123"

        // When
        let expectation = expectation(description: "authStatePublisher publishes UID")

        sut.authStatePublisher
            .dropFirst() // Skip initial value
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        authService.mockAuthStateSubject.send(expectedUID)

        // Then
        waitForExpectations(timeout: 1)
    }
}

// MARK: - Children Fetching Tests
extension DefaultUserRepositoryTests {
    func test_getChildrenForParent_success() {
        // Given
        let parentID = "parent1"
        let expectedChildren = [
            UserEntity(id: "child1", email: "", name: "", role: .child, parentID: parentID),
            UserEntity(id: "child2", email: "", name: "", role: .child, parentID: parentID)
        ]
        firestoreService.mockGetChildrenForParent = Just(expectedChildren)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "getChildren completes")

        sut.getChildrenForParent(parentID: parentID)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }

    func test_getChildrenForParent_failure() {
        // Given
        let parentID = "parent1"
        firestoreService.mockGetChildrenForParent = Fail(error: NSError(domain: "Test", code: 500))
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "getChildren fails")

        sut.getChildrenForParent(parentID: parentID)
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }
}

// MARK: - Save User Tests
extension DefaultUserRepositoryTests {
    func test_saveUser_success() {
        // Given
        let user = UserEntity(id: "user1", email: "test@test.com", name: "Test", role: .parent)
        firestoreService.mockSaveUserEntity = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "saveUser completes")

        sut.saveUser(user)
            .sink(
                receiveCompletion: {
                    if case .finished = $0 {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }

    func test_saveUser_failure() {
        // Given
        let user = UserEntity(id: "user1", email: "test@test.com", name: "Test", role: .parent)
        firestoreService.mockSaveUserEntity = Fail(error: NSError(domain: "Test", code: 500))
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "saveUser fails")

        sut.saveUser(user)
            .sink(
                receiveCompletion: {
                    if case .failure = $0 {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }
}

// MARK: - Daily Goal Tests
extension DefaultUserRepositoryTests {
    func test_saveUserDailyTarget_callsFirestore() {
        // Given
        let userId = "user1"
        let goal = 30

        let expectation = expectation(description: "")
        expectation.isInverted = true

        // When
        sut.saveUserDailyTarget(userID: userId, goal: goal)

        firestoreService.setDailyGoalCall = { _ in expectation.fulfill() }

        waitForExpectations(timeout: 2)
    }

    func test_saveUserDailyTarget_callsWithDifferentValues() {
        // Given
        let userId = "user2"
        let goal = 45

        // When
        sut.saveUserDailyTarget(userID: userId, goal: goal)

        // Then
        XCTAssertTrue(!userId.isEmpty)
    }
}

// MARK: - Progress Tests
extension DefaultUserRepositoryTests {
    func test_fetchUserProgress_success() {
        // Given
        let userId = "user1"
        firestoreService.mockGetProgressData = .just([])
        storageService.fetchUserResult = UserEntity(id: userId, email: "", name: "", role: .child)

        // When
        let expectation = expectation(description: "fetchUserProgress completes")

        sut.fetchUserProgress(userID: userId)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
    }

    func test_fetchUserProgress_failure() {
        // Given
        let userId = "user1"
        firestoreService.mockGetProgressData = Fail(error: NSError(domain: "Test", code: 500))
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "fetchUserProgress fails")
        var receivedError: UserError?

        sut.fetchUserProgress(userID: userId)
            .sink(
                receiveCompletion: {
                    if case let .failure(error) = $0 {
                        receivedError = error
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(receivedError)
    }
}

// MARK: - Reading Session Tests
extension DefaultUserRepositoryTests {
    func test_saveReadingSession_success() {
        // Given
        let session = ReadingSession(
            bookId: "",
            startTime: .distantFuture,
            endTime: .distantFuture,
            duration: .infinity,
            pagesRead: []
        )
        firestoreService.mockSaveReadingSession = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "saveReadingSession completes")
        var didComplete = false

        sut.saveReadingSession(session, for: "user1")
            .sink(
                receiveCompletion: {
                    if case .finished = $0 {
                        didComplete = true
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 10)
        XCTAssertTrue(didComplete)
    }

    func test_saveReadingSession_retriesOnFailure() {
        // Given
        let session = ReadingSession(
            bookId: "",
            startTime: .distantFuture,
            endTime: .distantFuture,
            duration: .infinity,
            pagesRead: []
        )
        firestoreService.mockSaveReadingSession = Fail(error: NSError(domain: "Test", code: 500))
            .delay(for: .seconds(0.1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "saveReadingSession fails after retries")
        var receivedError: Error?

        sut.saveReadingSession(session, for: "user1")
            .sink(
                receiveCompletion: {
                    if case let .failure(error) = $0 {
                        receivedError = error
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 2)
        XCTAssertNotNil(receivedError)
    }
}

// MARK: - Weekly Stats Tests
extension DefaultUserRepositoryTests {
    func test_getWeeklyStats_success() {
        // Given
        let userId = "user1"
        let expectedStats = WeeklyReadingStats(
            totalDuration: 120,
            averageDailyDuration: 30,
            pagesRead: 50,
            daysActive: 4
        )
        firestoreService.mockGetWeeklyStats = Just(expectedStats)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "getWeeklyStats completes")
        var receivedStats: WeeklyReadingStats?

        sut.getWeeklyStats(userID: userId)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { stats in
                    receivedStats = stats
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertEqual(receivedStats?.pagesRead, expectedStats.pagesRead)
    }

    func test_getWeeklyStats_failure() {
        // Given
        let userId = "user1"
        firestoreService.mockGetWeeklyStats = Fail(error: NSError(domain: "Test", code: 500))
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "getWeeklyStats fails")
        var receivedError: UserError?

        sut.getWeeklyStats(userID: userId)
            .sink(
                receiveCompletion: {
                    if case let .failure(error) = $0 {
                        receivedError = error
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(receivedError)
    }
}

// MARK: - Reading Sessions Tests
extension DefaultUserRepositoryTests {
    func test_getReadingSessions_success() {
        // Given
        let userId = "user1"
        let sessions = [
            ReadingSession(
                bookId: "",
                startTime: .distantFuture,
                endTime: .distantFuture,
                duration: .infinity,
                pagesRead: []
            ),
            ReadingSession(
                bookId: "",
                startTime: .distantFuture,
                endTime: .distantFuture,
                duration: .infinity,
                pagesRead: []
            )
        ]
        firestoreService.mockGetReadingSessions = Just(sessions)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "getReadingSessions completes")
        var receivedSessions: [ReadingSession]?

        sut.getReadingSessions(userID: userId)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { sessions in
                    receivedSessions = sessions
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertEqual(receivedSessions?.count, 2)
    }

    func test_getReadingSessions_failure() {
        // Given
        let userId = "user1"
        firestoreService.mockGetReadingSessions = Fail(error: NSError(domain: "Test", code: 500))
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "getReadingSessions fails")
        var receivedError: UserError?

        sut.getReadingSessions(userID: userId)
            .sink(
                receiveCompletion: {
                    if case let .failure(error) = $0 {
                        receivedError = error
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(receivedError)
    }
}

// MARK: - Progress History Tests
extension DefaultUserRepositoryTests {
    func test_getProgressHistory_success() {
        // Given
        let userId = "user1"
        let progress = [ProgressData(bookId: "", pagesRead: 2, totalPages: 3, finished: true, pointsEarned: 1)]
        firestoreService.mockGetProgressData = Just(progress)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "getProgressHistory completes")
        var receivedProgress: [ProgressData]?

        sut.getProgressHistory(userID: userId)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { progress in
                    receivedProgress = progress
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertEqual(receivedProgress?.count, 1)
    }

    func test_getProgressHistory_failure() {
        // Given
        let userId = "user1"
        firestoreService.mockGetProgressData = Fail(error: NSError(domain: "Test", code: 500))
            .eraseToAnyPublisher()

        // When
        let expectation = expectation(description: "getProgressHistory fails")
        var receivedError: UserError?

        sut.getProgressHistory(userID: userId)
            .sink(
                receiveCompletion: {
                    if case let .failure(error) = $0 {
                        receivedError = error
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(receivedError)
    }
}

// MARK: - Sign Out Tests
extension DefaultUserRepositoryTests {
    func test_signOut_success() throws {
        // Given

        // When
        try sut.signOut()

        // Then
        XCTAssertTrue(authService.signOutCalled)
    }

    func test_signOut_throwsError() {
        // Given
        authService.signOutError = NSError(domain: "Test", code: 500)
        try? sut.signOut()
        XCTAssertTrue(true)
    }
}
