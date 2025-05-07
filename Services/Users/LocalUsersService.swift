import Combine
import Resolver
import SwiftData

protocol LocalUsersService {
    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error>
    func getCurrentUser() -> AnyPublisher<UserEntity?, Never>
    func clearAllUsers() -> AnyPublisher<Void, Error>
}

final class DefaultLocalUsersService: LocalUsersService {
    private let context: ModelContext
    @Published private var currentUser: UserEntity?

    init(context: ModelContext = Resolver.resolve()) {
        self.context = context
        setupObserver()
    }

    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            self?.context.insert(user)
            self?.currentUser = user
            do {
                try self?.context.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func getCurrentUser() -> AnyPublisher<UserEntity?, Never> {
        $currentUser
            .eraseToAnyPublisher()
    }

    func clearAllUsers() -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            let descriptor = FetchDescriptor<UserEntity>()
            do {
                let users = try self?.context.fetch(descriptor) ?? []
                users.forEach { self?.context.delete($0) }
                try self?.context.save()
                self?.currentUser = nil
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    private func setupObserver() {
        let descriptor = FetchDescriptor<UserEntity>()
        do {
            let users = try context.fetch(descriptor)
            currentUser = users.first
        } catch {
            currentUser = nil
        }
    }
}
