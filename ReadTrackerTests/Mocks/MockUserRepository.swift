import Combine
@testable import ReadTracker

// swiftlint:disable large_tuple
class MockUserRepository: UserRepository {
    // MARK: - createUser
    var mockCreateUser: AnyPublisher<UserEntity, UserError> = .fail(.message("fail"))
    var createUserCallCount = 0
    var createUserParams: (name: String, email: String, password: String, role: Role)?

    func createUser(name: String, email: String, password: String, role: Role) -> AnyPublisher<UserEntity, UserError> {
        createUserCallCount += 1
        createUserParams = (name, email, password, role)
        return mockCreateUser
    }

    // MARK: - createChildUser
    var mockCreateChildUser: AnyPublisher<UserEntity, UserError> = .fail(.message("fail"))
    var createChildUserCallCount = 0
    var createChildUserParams: (name: String, email: String, password: String, parent: UserEntity)?

    func createChildUser(
        name: String,
        email: String,
        password: String,
        parent: UserEntity
    ) -> AnyPublisher<UserEntity, UserError> {
        createChildUserCallCount += 1
        createChildUserParams = (name, email, password, parent)
        return mockCreateChildUser
    }

    // MARK: - logIn
    var mockLogIn: AnyPublisher<UserEntity, UserError> = .fail(.message("fail"))
    var logInCallCount = 0
    var logInParams: (email: String, password: String)?

    func logIn(email: String, password: String) -> AnyPublisher<UserEntity, UserError> {
        logInCallCount += 1
        logInParams = (email, password)
        return mockLogIn
    }

    // MARK: - getCurrentUser
    var mockGetCurrentUser: AnyPublisher<UserEntity?, Never> = Just(nil).eraseToAnyPublisher()
    var getCurrentUserCallCount = 0

    func getCurrentUser() -> AnyPublisher<UserEntity?, Never> {
        getCurrentUserCallCount += 1
        return mockGetCurrentUser
    }

    // MARK: - authStatePublisher
    var mockAuthStatePublisher: AnyPublisher<String?, Never> = Just(nil).eraseToAnyPublisher()
    var authStatePublisherSubscriptionCount = 0

    var authStatePublisher: AnyPublisher<String?, Never> {
        authStatePublisherSubscriptionCount += 1
        return mockAuthStatePublisher
    }

    // MARK: - getChildrenForParent
    var mockGetChildrenForParent: AnyPublisher<[UserEntity], UserError> = .just([])
    var getChildrenForParentCallCount = 0
    var getChildrenForParentParams: String?

    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], UserError> {
        getChildrenForParentCallCount += 1
        getChildrenForParentParams = parentID
        return mockGetChildrenForParent
    }

    // MARK: - saveUser
    var mockSaveUser: AnyPublisher<Void, Error> = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    var saveUserCallCount = 0
    var saveUserParams: UserEntity?

    func saveUser(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        saveUserCallCount += 1
        saveUserParams = user
        return mockSaveUser
    }

    // MARK: - saveUserDailyTarget
    var saveUserDailyTargetCallCount = 0
    var saveUserDailyTargetParams: (userID: String, goal: Int)?

    func saveUserDailyTarget(userID: String, goal: Int) {
        saveUserDailyTargetCallCount += 1
        saveUserDailyTargetParams = (userID, goal)
    }

    // MARK: - fetchUserProgress
    var mockFetchUserProgress: AnyPublisher<[ProgressData], UserError> =
        .just([])
    var fetchUserProgressCallCount = 0
    var fetchUserProgressParams: String?

    func fetchUserProgress(userID: String) -> AnyPublisher<[ProgressData], UserError> {
        fetchUserProgressCallCount += 1
        fetchUserProgressParams = userID
        return mockFetchUserProgress
    }

    // MARK: - saveReadingSession
    var mockSaveReadingSession: AnyPublisher<Void, Error> = .just(())
    var saveReadingSessionCallCount = 0
    var saveReadingSessionParams: (session: ReadingSession, userID: String)?

    func saveReadingSession(_ session: ReadingSession, for userId: String) -> AnyPublisher<Void, Error> {
        saveReadingSessionCallCount += 1
        saveReadingSessionParams = (session, userId)
        return mockSaveReadingSession
    }

    // MARK: - getWeeklyStats
    var mockGetWeeklyStats: AnyPublisher<WeeklyReadingStats, UserError>
        = .fail(.message("fail"))
    var getWeeklyStatsCallCount = 0
    var getWeeklyStatsParams: String?

    func getWeeklyStats(userID: String) -> AnyPublisher<WeeklyReadingStats, UserError> {
        getWeeklyStatsCallCount += 1
        getWeeklyStatsParams = userID
        return mockGetWeeklyStats
    }

    // MARK: - getReadingSessions
    var mockGetReadingSessions: AnyPublisher<[ReadingSession], UserError>
        = .just([])
    var getReadingSessionsCallCount = 0
    var getReadingSessionsParams: String?

    func getReadingSessions(userID: String) -> AnyPublisher<[ReadingSession], UserError> {
        getReadingSessionsCallCount += 1
        getReadingSessionsParams = userID
        return mockGetReadingSessions
    }

    // MARK: - getProgressHistory
    var mockGetProgressHistory: AnyPublisher<[ProgressData], UserError> =
        .just([])
    var getProgressHistoryCallCount = 0
    var getProgressHistoryParams: String?

    func getProgressHistory(userID: String) -> AnyPublisher<[ProgressData], UserError> {
        getProgressHistoryCallCount += 1
        getProgressHistoryParams = userID
        return mockGetProgressHistory
    }

    // MARK: - signOut
    var signOutCallCount = 0
    var shouldThrowOnSignOut = false

    func signOut() throws {
        signOutCallCount += 1
        if shouldThrowOnSignOut {
            throw UserError.message("fail")
        }
    }
}

// swiftlint:enable large_tuple
