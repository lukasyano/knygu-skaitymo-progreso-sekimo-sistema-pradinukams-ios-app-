import Combine
import SwiftData
import Resolver

protocol LocalUsersService {
    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error>
    func getCurrentUser() -> AnyPublisher<UserEntity?, Never>
}

final class DefaultLocalUsersService: LocalUsersService {
    @Injected private var context: ModelContext
    @Published private var currentUser: UserEntity?
    
    init() {
        loadInitialUser()
    }
    
    func saveUserEntity(_ user: UserEntity) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            self?.clearExistingUsers()
            self?.context.insert(user)
            self?.currentUser = user
            self?.saveContext(promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> AnyPublisher<UserEntity?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
    
    func clearAllUsers() -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            self?.clearExistingUsers()
            self?.currentUser = nil
            self?.saveContext(promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    private func loadInitialUser() {
        let descriptor = FetchDescriptor<UserEntity>()
        currentUser = try? context.fetch(descriptor).first
    }
    
    private func clearExistingUsers() {
        (try? context.fetch(FetchDescriptor<UserEntity>()))?.forEach { context.delete($0) }
    }
    
    private func saveContext(promise: @escaping (Result<Void, Error>) -> Void) {
        do {
            try context.save()
            promise(.success(()))
        } catch {
            promise(.failure(error))
        }
    }
}
