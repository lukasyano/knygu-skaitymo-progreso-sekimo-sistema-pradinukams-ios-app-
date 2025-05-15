// BookReaderInteractor.swift
import Combine
import Foundation
import Resolver

protocol BookReaderInteractor: AnyObject {
    func viewDidAppear()
    func onBookPageChanged(_ page: Int)
    func getBookProgress() -> ProgressData?
    func startNewSession()
    func saveSessionDurationFromCurrentSession()
}

final class DefaultBookReaderInteractor {
    // MARK: - Properties
    private weak var presenter: BookReaderPresenter?
    private weak var coordinator: (any BookReaderCoordinator)?

    private let book: BookEntity
    private let userRepository: UserRepository
    private let bookRepository: BookRepository
    private var user: UserEntity

    private var cancelBag = Set<AnyCancellable>()
    private var currentSession: ReadingSession?
    private var currentPages: [PageRead] = []
    private var retentionToken: AnyObject?

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
    func startNewSession() {
        guard currentSession == nil else {
            print("[Session] Session already exists")
            return
        }

        currentSession = ReadingSession(
            bookId: book.id,
            startTime: Date(),
            endTime: Date(),
            duration: 0,
            pagesRead: []
        )
        print("[Session] New session started: \(currentSession!.startTime)")
    }

    func saveSessionDurationFromCurrentSession() {
        guard let session = currentSession else {
            print("[Session] Nothing to save ")
            return
        }

        let duration = Date().timeIntervalSince(session.startTime)
        saveSession(session, duration: duration)
    }

    private func saveSession(_ session: ReadingSession, duration: TimeInterval) {
        var sessionToSave = session
        sessionToSave.endTime = Date()
        sessionToSave.duration = duration
        sessionToSave.pagesRead = currentPages

        retentionToken = self

        userRepository.saveReadingSession(sessionToSave, for: user.id)
            .sink { [weak self] completion in
                self?.retentionToken = nil
                switch completion {
                case .finished:
                    print("[Session] Saved \(sessionToSave.pagesRead.count) pages")
                    self?.clearCurrentSession()

                case let .failure(error):
                    print("[Session] Save failed - keeping session for retry: \(error)")
                    self?.currentSession = sessionToSave // Restore session
                    self?.currentPages = sessionToSave.pagesRead
                }
            } receiveValue: { _ in }
            .store(in: &cancelBag)
    }

    func clearCurrentSession() {
        currentSession = nil
        currentPages.removeAll()
        print("[Session] Session cleared")
    }

    func onBookPageChanged(_ page: Int) {
        guard let totalPages = book.totalPages else { return }

        let validatedPage = min(max(page, 1), totalPages)

        let pageRead = PageRead(
            pageNumber: validatedPage,
            timestamp: Date()
        )

        if currentPages.last?.pageNumber != validatedPage {
            currentPages.append(pageRead)
            print("[Page] Tracked page \(validatedPage). Total: \(currentPages.count)")
        }

        DispatchQueue.main.async {
            self.updateUserProgress(newPage: validatedPage, totalPages: totalPages)
        }
    }

    private func updateUserProgress(newPage: Int, totalPages: Int) {
        let progress = user.progressData.first { $0.bookId == book.id } ?? ProgressData(
            bookId: book.id,
            pagesRead: 0,
            totalPages: totalPages,
            finished: false,
            pointsEarned: 0
        )

        let newPages = max(newPage, progress.pagesRead)
        let pointsDelta = (newPages / 10) - progress.pointsEarned

        guard newPages > progress.pagesRead || pointsDelta > 0 else { return }

        progress.pagesRead = newPages
        progress.pointsEarned = newPages / 10
        progress.finished = newPages >= totalPages

        if let index = user.progressData.firstIndex(where: { $0.bookId == book.id }) {
            user.progressData[index] = progress
        } else {
            user.progressData.append(progress)
        }

        user.totalPoints += pointsDelta

        userRepository.saveUser(user)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("[Progress] Failed to save progress: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] _ in
                if pointsDelta > 0 {
                    self?.presenter?.presentCelebrate()
                }
            }
            .store(in: &cancelBag)
    }

    func getBookProgress() -> ProgressData? {
        user.progressData.first { $0.bookId == book.id }
    }

    func viewDidAppear() {
        cancelBag.removeAll()
    }

    private func printSessionDetails(_ session: ReadingSession) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        print("""
        [Session Details]
        - User ID: \(user.id)
        - Book ID: \(session.bookId)
        - Start: \(formatter.string(from: session.startTime))
        - End: \(formatter.string(from: session.endTime))
        - Duration: \(session.duration.formatted())s
        - Pages: \(session.pagesRead.map { $0.pageNumber })
        """)
    }
}
