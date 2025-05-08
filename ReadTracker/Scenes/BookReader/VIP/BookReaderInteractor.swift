// BookReaderInteractor.swift
import Combine
import Foundation
import Resolver

protocol BookReaderInteractor: AnyObject {
    func viewDidAppear()
    func onBookPageChanged(_ page: Int)
    func getBookProgress() -> ProgressData?
}

final class DefaultBookReaderInteractor {
    // MARK: - Properties
    private weak var presenter: BookReaderPresenter?
    private weak var coordinator: (any BookReaderCoordinator)?
    private var cancelBag = Set<AnyCancellable>()

    private let bookEntity: BookEntity
    private let userRepository: UserRepository
    private let bookRepository: BookRepository
    private var user: UserEntity

    init(
        coordinator: (any BookReaderCoordinator)?,
        presenter: BookReaderPresenter?,
        userRepository: UserRepository = Resolver.resolve(),
        bookRepository: BookRepository = Resolver.resolve(),
        user: UserEntity,
        bookEntity: BookEntity
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.userRepository = userRepository
        self.bookRepository = bookRepository
        self.user = user
        self.bookEntity = bookEntity
    }
}

extension DefaultBookReaderInteractor: BookReaderInteractor {
    func onBookPageChanged(_ page: Int) {
        guard let totalPages = bookEntity.totalPages else { return }

        guard page > 0, page <= totalPages else { return }

        var progress = user.progressData.first { $0.bookId == bookEntity.id } ?? ProgressData(
            bookId: bookEntity.id,
            pagesRead: 0,
            totalPages: totalPages,
            finished: false,
            pointsEarned: 0
        )

        // Calculate based on total pages read, not increment
        let previousPages = progress.pagesRead
        let newPages = max(page, previousPages) // Don't allow going backward
        let totalPointsEarned = newPages / 10
        let pointsDelta = totalPointsEarned - progress.pointsEarned

        guard newPages > previousPages || pointsDelta > 0 else { return }

        progress.pagesRead = newPages
        progress.pointsEarned = totalPointsEarned
        progress.finished = newPages >= totalPages

        if let index = user.progressData.firstIndex(where: { $0.bookId == bookEntity.id }) {
            user.progressData[index] = progress
        } else {
            user.progressData.append(progress)
        }

        user.totalPoints += pointsDelta

        // Save updates
        userRepository.saveUser(user)
            .sink(receiveCompletion: { [weak self] _ in
//                if case .failure(let error) = completion {
//                    self?.coordinator?.presentError(message: "Failed to save progress: \(error.localizedDescription)")
//                }
            }, receiveValue: { [weak self] _ in
                self?.presenter?.presentCelebrate()
                // self?.presenter?.presentProgressUpdate(progress: progress)
            })
            .store(in: &cancelBag)
    }

    func getBookProgress() -> ProgressData? {
        user.progressData.first { $0.bookId == bookEntity.id }
    }

    func viewDidAppear() {
        cancelBag.removeAll()
        //   presenter?.presentInitialProgress(getBookProgress())
    }
}
