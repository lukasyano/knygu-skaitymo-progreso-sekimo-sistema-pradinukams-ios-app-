import Combine
import Foundation
import Resolver
import SwiftData

enum UserServiceError: Error {
    case userNotFound
    case parentNotFound
    case childNotFound
}

protocol UsersSwiftDataService {
    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error>

    func getUserRole(userID: String) -> AnyPublisher<Role?, Never>
    func linkChildToParent(childID: String, parentID: String) -> AnyPublisher<Void, Error>
    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], Error>
    func getAllParents() -> AnyPublisher<[UserEntity], Error>
}

class DefaultUsersSwiftDataService: UsersSwiftDataService {
    private let context: ModelContext

    init(context: ModelContext = Resolver.resolve()) {
        self.context = context
    }

    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else { return }

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

    func getUserRole(userID: String) -> AnyPublisher<Role?, Never> {
        Future { [weak self] promise in
            guard let self else { return }

            let fetch = FetchDescriptor<UserEntity>(predicate: #Predicate { $0.id == userID })
            do {
                let user = try context.fetch(fetch).first
                promise(.success(user?.role))
            } catch {
                promise(.success(nil))
            }
        }
        .eraseToAnyPublisher()
    }

    func linkChildToParent(childID: String, parentID: String) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else { return }
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

    func getChildrenForParent(parentID: String) -> AnyPublisher<[UserEntity], Error> {
        Future { [weak self] promise in
            guard let self else { return }
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

    func getAllParents() -> AnyPublisher<[UserEntity], Error> {
        Future { [weak self] promise in
            guard let self else { return }
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
