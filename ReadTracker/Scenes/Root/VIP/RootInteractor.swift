import Combine
import Foundation
import Resolver
import SwiftData

protocol RootInteractor: AnyObject {
    func onAppear()
    func onDisappear()
}

final class DefaultRootInteractor {
    private weak var coordinator: DefaultRootCoordinator?

    private let bookRepository: BookRepository
    private let userRepository: UserRepository

    private var hasPerformedInitialRefresh = false

    // Combine bag
    private var cancelBag = Set<AnyCancellable>()
    private var authStatecancelBag = Set<AnyCancellable>()

    init(
        coordinator: DefaultRootCoordinator = Resolver.resolve(),
        bookRepsitory: BookRepository = Resolver.resolve(),
        userRepository: UserRepository = Resolver.resolve()
    ) {
        self.coordinator = coordinator
        self.bookRepository = bookRepsitory
        self.userRepository = userRepository
        refreshBooksIfNeeded()
    }
}

// MARK: - Business Logic

extension DefaultRootInteractor: RootInteractor {
    private func refreshBooksIfNeeded() {
        bookRepository.refreshIfNeeded()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: {}
            )
            .store(in: &cancelBag)
    }

    func onAppear() {
        let logOutDelay: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(200)

        userRepository.authStatePublisher
            .removeDuplicates()
            .subscribe(on: DispatchQueue.global())
            .delay(for: logOutDelay, scheduler: DispatchQueue.main)
            .sink { [weak coordinator] userId in

                guard userId != .none else {
                    coordinator?.route = .authentication
                    return
                }
                coordinator?.route = .home
            }
            .store(in: &authStatecancelBag)
    }

    func onDisappear() {
        cancelBag.removeAll()
    }
}
