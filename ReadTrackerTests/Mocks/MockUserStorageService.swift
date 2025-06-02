import Foundation
@testable import ReadTracker

class MockUserStorageService: UserStorageService {

    // MARK: - saveUser
    var saveUserCall: Closure<UserEntity>?
    var saveUserError: Error?

    func saveUser(_ user: UserEntity) throws {
        saveUserCall?(user)
        if let error = saveUserError {
            throw error
        }
    }

    // MARK: - fetchUser
    var fetchUserCall: Closure<String>?
    var fetchUserResult: UserEntity?
    var fetchUserError: Error?

    func fetchUser(byId id: String) throws -> UserEntity? {
        fetchUserCall?(id)
        if let error = fetchUserError {
            throw error
        }
        return fetchUserResult
    }

    // MARK: - deleteUser
    var deleteUserCall: Closure<UserEntity>?
    var deleteUserError: Error?

    func deleteUser(_ user: UserEntity) throws {
        deleteUserCall?(user)
        if let error = deleteUserError {
            throw error
        }
    }
}
