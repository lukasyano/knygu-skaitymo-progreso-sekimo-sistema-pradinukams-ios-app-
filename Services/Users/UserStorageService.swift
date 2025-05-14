import Combine
import Foundation
import Resolver
import SwiftData

protocol UserStorageService {
    func saveUser(_ user: UserEntity) throws
    func fetchUser(byId id: String) throws -> UserEntity?
    func deleteUser(_ user: UserEntity) throws
}

final class DefaultUserStorageService: UserStorageService {
    @Injected private var context: ModelContext

    func saveUser(_ user: UserEntity) throws {
        if let existing = try fetchUser(byId: user.id) {
            existing.email = user.email
            existing.name = user.name
            existing.role = user.role
            existing.totalPoints = user.totalPoints
            existing.parentID = user.parentID
            existing.childrensID = user.childrensID
            existing.dailyReadingGoal = user.dailyReadingGoal

            existing.progressData = user.progressData.map { progress in
                progress
            }
            print("updated user")
        } else {
            let newUser = UserEntity(
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                parentID: user.parentID,
                childrensID: user.childrensID,
                totalPoints: user.totalPoints,
                dailyReadingGoal: user.dailyReadingGoal ?? 10
            )
            newUser.progressData = user.progressData
            context.insert(newUser)
            print("insert newUser with id:\(newUser.id)")
        }

        try context.save()
        print("save completed")
    }

    func fetchUser(byId id: String) throws -> UserEntity? {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func deleteUser(_ user: UserEntity) throws {
        context.delete(user)
        try context.save()
    }
}
