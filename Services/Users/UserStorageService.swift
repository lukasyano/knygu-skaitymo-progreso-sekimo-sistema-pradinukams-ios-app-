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

        target.email = incoming.email
        target.name = incoming.name
        target.role = incoming.role
        target.totalPoints = incoming.totalPoints
        target.parentID = incoming.parentID
        target.childrensID = incoming.childrensID
        target.dailyReadingGoal = incoming.dailyReadingGoal

        target.progressData.removeAll()
        for src in incoming.progressData {
            let progressData = ProgressData(
                bookId: src.bookId,
                pagesRead: src.pagesRead,
                totalPages: src.totalPages,
                finished: src.finished,
                pointsEarned: src.pointsEarned
            )
            progressData.user = target
            context.insert(progressData)
            target.progressData.append(progressData)
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
