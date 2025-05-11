import SwiftUI

protocol BookReaderCoordinator: Coordinator {
    func presentError(
        error: String,
        onDismiss: @escaping () -> Void
    )
    func presentBookReaderComplete(
        message: String,
        onDismiss: @escaping () -> Void
    )
}

final class DefaultBookReaderCoordinator: BookReaderCoordinator {
    private var interactor: BookReaderInteractor!
    private var presenter: BookReaderPresenter!
    @Published private var viewModel: DefaultBookReaderViewModel!
    weak var parent: (any Coordinator)?
    @Published var presentedView: BookReaderCoordinatorPresentedView?
    @Published var route: BookReaderCoordinatorRoute?
    private let book: BookEntity
    private let user: UserEntity

    init(book: BookEntity, user: UserEntity, parent: (any Coordinator)?) {
        self.book = book
        self.user = user
        self.parent = parent
        self.viewModel = DefaultBookReaderViewModel()
        self.presenter = DefaultBookReaderPresenter(displayLogic: viewModel)
        self.interactor = DefaultBookReaderInteractor(
            coordinator: self,
            presenter: presenter,
            user: user, book: book
        )
    }

    func start() -> some View {
        BookReaderView(interactor: interactor, viewModel: viewModel, book: book, user: user)
    }
}

// MARK: - Presentation

extension DefaultBookReaderCoordinator {
    func presentError(
        error: String,
        onDismiss: @escaping () -> Void
    ) {
        presentedView = .validationError(error: error, onDismiss: onDismiss)
    }

    func presentBookReaderComplete(
        message: String,
        onDismiss: @escaping () -> Void
    ) {
        presentedView = .infoMessage(message: message, onDismiss: onDismiss)
    }
}

// MARK: - Navigation

extension DefaultBookReaderCoordinator {}
