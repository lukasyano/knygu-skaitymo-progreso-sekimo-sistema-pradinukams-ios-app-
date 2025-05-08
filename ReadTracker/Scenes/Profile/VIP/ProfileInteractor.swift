import Combine
import FirebaseAuth
import Foundation
import Resolver

protocol ProfileInteractor: AnyObject {
    func viewDidAppear()
    func createChild(name: String, email: String, password: String)
}

final class DefaultProfileInteractor {
    // VIP
    private weak var presenter: ProfilePresenter?
    private weak var coordinator: (any ProfileCoordinator)?

    // Properties
    private(set) var email: String = ""
    private(set) var name: String = ""
    private(set) var password: String = ""
    private lazy var cancelBag = Set<AnyCancellable>()

    private(set) var user: UserEntity
    private(set) var childrends: [UserEntity]?
    private var progress: [ProgressData] = []
    // Repositories
    private let userRepository: UserRepository

    // MARK: - Lifecycle

    init(
        coordinator: (any ProfileCoordinator)?,
        presenter: ProfilePresenter?,
        userRepository: UserRepository = Resolver.resolve(),
        user: UserEntity
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.userRepository = userRepository
        self.user = user
        presenter?.presentUser(user)
    }
}

// MARK: - Business Logic

extension DefaultProfileInteractor: ProfileInteractor {
    func createChild(name: String, email: String, password: String) {
        presenter?.presentLoading(true)

        let parent = user
        userRepository.createChildUser(
            name: name,
            email: email,
            password: password,
            parent: parent
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] in self?.handleRegistrationCompletion($0) },
            receiveValue: { [weak self] in self?.handleRegistrationSuccess($0) }
        )
        .store(in: &cancelBag)
    }

    private func handleRegistrationSuccess(_ user: UserEntity) {
        coordinator?.presentProfileComplete(
            message: "Vaikas sėkmingai sukurtas bei priskirtas prie jūsų profilio",
            onDismiss: { [weak self] in
                self?.presenter?.presentLoading(false)
                do {
                    try self?.userRepository.signOut()
                } catch {}
            }
        )
    }

    private func handleRegistrationCompletion(_ completion: Subscribers.Completion<UserError>) {
        if case let .failure(.message(message)) = completion {
            presenter?.presentLoading(false)
            coordinator?.presentError(error: message, onDismiss: {})
        }
    }

    // MARK: - View Did Change

    func viewDidAppear() {
        //cancelBag.removeAll()
        fetchChildrends()
        loadUserProgress()
    }

    private func fetchChildrends() {
        userRepository.getChildrenForParent(parentID: user.id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error fetching children: \(error)")
                }
            }, receiveValue: { [weak self] children in
                self?.childrends = children
                self?.presenter?.presentChilds(children)
            })
            .store(in: &cancelBag)
    }
    
    private func loadUserProgress() {
        userRepository.fetchUserProgress(userID: user.id)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Firestore Error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] progressData in
                self?.progress = progressData
                self?.presenter?.presentProgress(progressData)
            }
            .store(in: &cancelBag)
    }
}
