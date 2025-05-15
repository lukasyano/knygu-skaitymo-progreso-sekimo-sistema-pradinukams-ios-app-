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

    func saveUser(_ incoming: UserEntity) throws {
        // 1. Locate or create the target user *inside the current context*
        let target: UserEntity
        if let existing = try fetchUser(byId: incoming.id) {
            target = existing
        } else {
            target = UserEntity(
                id: incoming.id,
                email: incoming.email,
                name: incoming.name,
                role: incoming.role,
                parentID: incoming.parentID,
                childrensID: incoming.childrensID,
                totalPoints: incoming.totalPoints,
                dailyReadingGoal: incoming.dailyReadingGoal ?? 10
            )
            context.insert(target)
        }

        // 2. Copy the *scalars* you actually want
        target.email = incoming.email
        target.name = incoming.name
        target.role = incoming.role
        target.totalPoints = incoming.totalPoints
        target.parentID = incoming.parentID
        target.childrensID = incoming.childrensID
        target.dailyReadingGoal = incoming.dailyReadingGoal

        // 3. Replace the progress list with *fresh* objects in this context
        target.progressData.removeAll()
        for src in incoming.progressData {
            let pd = ProgressData(
                bookId: src.bookId,
                pagesRead: src.pagesRead,
                totalPages: src.totalPages,
                finished: src.finished,
                pointsEarned: src.pointsEarned
            )
            pd.user = target // set the inverse
            context.insert(pd) // explicit insert → same context
            target.progressData.append(pd)
        }

        try context.save()
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
