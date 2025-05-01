import SwiftUI

private enum ViewConstants {}

struct HomeView<ViewModel: HomeViewModel>: View {
    // MARK: - Variables
    private unowned var interactor: HomeInteractor
    @ObservedObject private var viewModel: ViewModel

    // MARK: - Init
    init(
        interactor: HomeInteractor,
        viewModel: ViewModel
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
            } else {
                contentView
            }
        }
        .onAppear(perform: { [weak interactor] in interactor?.viewDidChange(.onAppear) })
        .onDisappear(perform: { [weak interactor] in interactor?.viewDidChange(.onDisappear) })
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(viewModel.books) { book in
                    VStack(spacing: 8) {
                        Image(uiImage: book.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .cornerRadius(12)
                            .shadow(radius: 4)

                        Text(book.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 4)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
            .padding()
        }
    }
}
