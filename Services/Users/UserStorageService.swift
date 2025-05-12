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
            context.delete(existing)
        }
        context.insert(user)
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
