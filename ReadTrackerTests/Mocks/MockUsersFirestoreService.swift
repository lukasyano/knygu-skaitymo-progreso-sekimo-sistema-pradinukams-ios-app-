//
//  MockUsersFirestoreService.swift
//  ReadTracker
//
//  Created by Lukas Toliušis   on 02/06/2025.
//

import Combine
@testable import ReadTracker

class MockUsersFirestoreService: UsersFirestoreService {
    // MARK: - saveUserEntity
    var mockSaveUserEntity: AnyPublisher<Void, Error> = Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    var saveUserEntityCall: Closure<UserEntity>?

    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        defer { saveUserEntityCall?(user) }
        return mockSaveUserEntity
    }

    // MARK: - updateParentWithChild
    var mockUpdateParentWithChild: AnyPublisher<Void, Error> = Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    var updateParentWithChildCall: Closure<(String, String)>?

    func updateParentWithChild(parentID: String, childID: String) -> AnyPublisher<Void, Error> {
        defer { updateParentWithChildCall?((parentID, childID)) }
        return mockUpdateParentWithChild
    }

    // MARK: - getUserEntity
    var mockGetUserEntity: AnyPublisher<UserEntity, Error> = Just(.init(id: "", email: "", name: "", role: .child))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    var getUserEntityCall: Closure<String>?

    func getUserEntity(userID: String) -> AnyPublisher<UserEntity, Error> {
        defer { getUserEntityCall?(userID) }
        return mockGetUserEntity
    }

    // MARK: - getChildrenForParent
    var mockGetChildrenForParent: AnyPublisher<[UserEntity], Error> = Just([])
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    var getChildrenForParentCall: Closure<String>?

    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], Error> {
        defer { getChildrenForParentCall?(parentID) }
        return mockGetChildrenForParent
    }

    // MARK: - getProgressData
    var mockGetProgressData: AnyPublisher<[ProgressData], Error> = Just([])
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    var getProgressDataCall: Closure<String>?

    func getProgressData(userID: String) -> AnyPublisher<[ProgressData], Error> {
        defer { getProgressDataCall?(userID) }
        return mockGetProgressData
    }

    // MARK: - saveReadingSession
    var mockSaveReadingSession: AnyPublisher<Void, Error> = Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    var saveReadingSessionCall: Closure<(String, ReadingSession)>?

    func saveReadingSession(userID: String, session: ReadingSession) -> AnyPublisher<Void, Error> {
        defer { saveReadingSessionCall?((userID, session)) }
        return mockSaveReadingSession
    }

    // MARK: - getReadingSessions
    var mockGetReadingSessions: AnyPublisher<[ReadingSession], Error> = Just([])
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    var getReadingSessionsCall: Closure<String>?

    func getReadingSessions(userID: String) -> AnyPublisher<[ReadingSession], Error> {
        defer { getReadingSessionsCall?(userID) }
        return mockGetReadingSessions
    }

    // MARK: - getWeeklyStats
    var mockGetWeeklyStats: AnyPublisher<WeeklyReadingStats, Error> =
        .just(.init(totalDuration: .infinity, averageDailyDuration: .infinity, pagesRead: 1, daysActive: 22))

    var getWeeklyStatsCall: Closure<String>?

    func getWeeklyStats(userID: String) -> AnyPublisher<WeeklyReadingStats, Error> {
        defer { getWeeklyStatsCall?(userID) }
        return mockGetWeeklyStats
    }

    // MARK: - setDailyGoal
    var setDailyGoalCall: Closure<(String, Int)>?

    func setDailyGoal(userId: String, goal: Int) {
        setDailyGoalCall?((userId, goal))
    }
}
