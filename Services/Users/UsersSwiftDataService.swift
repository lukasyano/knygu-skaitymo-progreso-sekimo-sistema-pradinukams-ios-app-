import Combine
import Foundation
import SwiftData

enum UserServiceError: Error {
    case userNotFound
    case parentNotFound
    case childNotFound
}

protocol UsersSwiftDataService {
    func saveUserEntity(_ user: UserEntity, context: ModelContext) -> AnyPublisher<Void, Error>

    func getUserRole(userID: String, context: ModelContext) -> AnyPublisher<Role?, Never>
    func linkChildToParent(childID: String, parentID: String, context: ModelContext) -> AnyPublisher<Void, Error>
    func getChildrenForParent(parentID: String, context: ModelContext) -> AnyPublisher<[UserEntity], Error>
    func getAllParents(context: ModelContext) -> AnyPublisher<[UserEntity], Error>
}

class DefaultUsersSwiftDataService: UsersSwiftDataService {
    func saveUserEntity(_ user: UserEntity, context: ModelContext) -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                let userID = user.id
                let descriptor = FetchDescriptor<UserEntity>(
                    predicate: #Predicate { $0.id == userID }
                )
                let existing = try context.fetch(descriptor).first

                if let existingUser = existing {
                    existingUser.email = user.email
                    existingUser.name = user.name
                    existingUser.role = user.role
                    existingUser.parentID = user.parentID
                    existingUser.childrensID = user.childrensID
                    existingUser.points = user.points
                    existingUser.totalPoints = user.totalPoints
                    existingUser.progressEntries = user.progressEntries
                } else {
                    context.insert(user)
                }

                try context.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func getUserRole(userID: String, context: ModelContext) -> AnyPublisher<Role?, Never> {
        Future { promise in
            let fetch = FetchDescriptor<UserEntity>(predicate: #Predicate { $0.id == userID })
            do {
                let user = try context.fetch(fetch).first
                promise(.success(user?.role))
            } catch {
                // In your original code this method does not return an error
                promise(.success(nil))
            }
        }
        .eraseToAnyPublisher()
    }

    func linkChildToParent(childID: String, parentID: String, context: ModelContext) -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                let fetchChild = FetchDescriptor<UserEntity>(predicate: #Predicate { $0.id == childID })
                let fetchParent = FetchDescriptor<UserEntity>(predicate: #Predicate { $0.id == parentID })

                guard let child = try context.fetch(fetchChild).first else {
                    return promise(.failure(UserServiceError.childNotFound))
                }

                guard let parent = try context.fetch(fetchParent).first else {
                    return promise(.failure(UserServiceError.parentNotFound))
                }

                child.parent = parent
                child.parentID = parent.id

                if !parent.children.contains(where: { $0.id == child.id }) {
                    parent.children.append(child)
                }

                if !parent.childrensID.contains(child.id) {
                    parent.childrensID.append(child.id)
                }

                try context.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func getChildrenForParent(parentID: String, context: ModelContext) -> AnyPublisher<[UserEntity], Error> {
        Future { promise in
            do {
                let fetchParent = FetchDescriptor<UserEntity>(predicate: #Predicate { $0.id == parentID })
                guard let parent = try context.fetch(fetchParent).first else {
                    return promise(.failure(UserServiceError.parentNotFound))
                }

                promise(.success(parent.children))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func getAllParents(context: ModelContext) -> AnyPublisher<[UserEntity], Error> {
        Future { promise in
            do {
                let allUsers = try context.fetch(FetchDescriptor<UserEntity>())
                let parents = allUsers.filter { $0.role == .parent }
                promise(.success(parents))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}
