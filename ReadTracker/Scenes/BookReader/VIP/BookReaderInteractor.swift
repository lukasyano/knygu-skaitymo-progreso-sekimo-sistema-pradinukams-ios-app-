// BookReaderInteractor.swift
import Combine
import Foundation
import Resolver

protocol BookReaderInteractor: AnyObject {
    func viewDidAppear()
    func onBookPageChanged(_ page: Int)
    //  func onBookMarkedAsFinished()
    func getBookProgress() -> ProgressData?
    func saveSessionDuration(_ duration: TimeInterval)
    func startNewSession()
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

    private var currentSession: ReadingSession?
    private var currentPages: [PageRead] = []
    private var sessionTimer: Timer?
    private var totalSessionDuration: TimeInterval = 0
    private let sessionUpdateInterval: TimeInterval = 60

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

extension DefaultBookReaderInteractor: BookReaderInteractor {
    func saveSessionDuration(_ duration: TimeInterval) {
        guard user.role != .parent else { return }

        currentSession?.endTime = Date()
        currentSession?.duration = duration
        currentSession?.pagesRead = currentPages

        guard let session = currentSession else { return }

        // Save to Firestore
        userRepository.saveReadingSession(session, for: user.id)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancelBag)

        // Reset session
        currentSession = nil
        currentPages.removeAll()
    }

    func startNewSession() {
        currentSession = ReadingSession(
            bookId: book.id,
            startTime: Date(),
            endTime: Date(),
            duration: 0,
            pagesRead: []
        )
        startSessionTimer()
    }

    private func startSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(
            withTimeInterval: sessionUpdateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateSessionDuration()
        }
    }

    private func updateSessionDuration() {
        guard let start = currentSession?.startTime else { return }
        currentSession?.duration = Date().timeIntervalSince(start)
        totalSessionDuration = currentSession?.duration ?? 0
    }

    func onBookPageChanged(_ page: Int) {
        guard let totalPages = book.totalPages else { return }
        guard page > 0, page <= totalPages else { return }

        let pageRead = PageRead(pageNumber: page, timestamp: Date())
        currentPages.append(pageRead)

        let progress = user.progressData.first { $0.bookId == book.id } ?? ProgressData(
            bookId: book.id,
            pagesRead: 0,
            totalPages: totalPages,
            finished: false,
            pointsEarned: 0
        )

        let previousPages = progress.pagesRead
        let newPages = max(page, previousPages)
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
            .sink(receiveCompletion: { [weak self] _ in }, receiveValue: { [weak self] _ in
                if pointsDelta > 0 {
                    self?.presenter?.presentCelebrate()
                }
            })
            .store(in: &cancelBag)
    }

    func getBookProgress() -> ProgressData? {
        user.progressData.first { $0.bookId == book.id }
    }

    func viewDidAppear() {
        cancelBag.removeAll()
    }
}
