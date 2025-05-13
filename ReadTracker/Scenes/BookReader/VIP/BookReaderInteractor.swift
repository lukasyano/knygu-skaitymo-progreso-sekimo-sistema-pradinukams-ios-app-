// BookReaderInteractor.swift
import Combine
import Foundation
import Resolver

protocol BookReaderInteractor: AnyObject {
    func viewDidAppear()
    func onBookPageChanged(_ page: Int)
    func getBookProgress() -> ProgressData?
    func saveSessionDuration(_ duration: TimeInterval)
}

final class DefaultBookReaderInteractor {
    // MARK: - Properties
    private weak var presenter: BookReaderPresenter?
    private weak var coordinator: (any BookReaderCoordinator)?
    private var cancelBag = Set<AnyCancellable>()

    private let book: BookEntity
    private let userRepository: UserRepository
    private let bookRepository: BookRepository
    private var user: UserEntity

    init(
        coordinator: (any BookReaderCoordinator)?,
        presenter: BookReaderPresenter?,
        userRepository: UserRepository = Resolver.resolve(),
        bookRepository: BookRepository = Resolver.resolve(),
        user: UserEntity,
        book: BookEntity
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.userRepository = userRepository
        self.bookRepository = bookRepository
        self.user = user
        self.book = book
    }
}

struct ReadingSession: Codable {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
}

extension DefaultBookReaderInteractor: BookReaderInteractor {
    func saveSessionDuration(_ duration: TimeInterval) {
        guard user.role != .parent else { return }

        // Update user's reading sessions
        let newSession = ReadingSession(
            startTime: Date().addingTimeInterval(-duration),
            endTime: Date(),
            duration: duration
        )
        // user.readingSessions.append(newSession)

        userRepository.saveUser(user)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancelBag)
    }

    func onBookPageChanged(_ page: Int) {
        guard let totalPages = book.totalPages else { return }

        guard page > 0, page <= totalPages else { return }

        let progress = user.progressData.first { $0.bookId == book.id } ?? ProgressData(
            bookId: book.id,
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

        if let index = user.progressData.firstIndex(where: { $0.bookId == book.id }) {
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
                if pointsDelta > 0 {
                    self?.presenter?.presentCelebrate()
                }
                // self?.presenter?.presentProgressUpdate(progress: progress)
            })
            .store(in: &cancelBag)
    }

    func getBookProgress() -> ProgressData? {
        user.progressData.first { $0.bookId == book.id }
    }

    func viewDidAppear() {
        cancelBag.removeAll()
        //   presenter?.presentInitialProgress(getBookProgress())
    }
}
