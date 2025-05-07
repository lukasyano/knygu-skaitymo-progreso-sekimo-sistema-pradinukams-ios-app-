import SwiftUI

struct BookReaderView<ViewModel: BookReaderViewModel>: View {
    // MARK: - Variables
    @Environment(\.dismiss) private var dismiss
    let url: URL

    private unowned var interactor: BookReaderInteractor
    @ObservedObject private var viewModel: ViewModel

    init(
        interactor: BookReaderInteractor,
        viewModel: ViewModel,
        url: URL
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
        self.url = url
    }

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            ZStack(alignment: .bottom) {
                PDFDocumentView(
                    url: url) { [weak interactor] in interactor?.onBookPageChanged($0) }

                HoldToDismissButton(action: dismiss.callAsFunction)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 30)
            }
        }
        .onAppear { [weak interactor] in interactor?.viewDidAppear() }
        .animation(.easeInOut, value: viewModel.isLoading)
    }
}
