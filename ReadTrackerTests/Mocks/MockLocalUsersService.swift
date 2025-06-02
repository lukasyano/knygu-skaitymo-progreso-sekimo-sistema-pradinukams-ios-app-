import Combine
@testable import ReadTracker

class MockLocalUsersService: LocalUsersService {
    // MARK: - saveUserEntity
    var mockSaveUserEntity: AnyPublisher<Void, Error> = Just(())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()

    var saveUserEntityCall: Closure<UserEntity>?

    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        defer { saveUserEntityCall?(user) }
        return mockSaveUserEntity
    }

    // MARK: - getCurrentUser
    var mockGetCurrentUser: AnyPublisher<UserEntity?, Never> = Just(nil).eraseToAnyPublisher()

    var getCurrentUserCall: Closure<Void>?

    func getCurrentUser() -> AnyPublisher<UserEntity?, Never> {
        defer { getCurrentUserCall?(()) }
        return mockGetCurrentUser
    }
}
