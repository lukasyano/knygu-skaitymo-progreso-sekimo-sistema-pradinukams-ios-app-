import SwiftUI

private enum ViewConstants {}

struct HomeView<ViewModel: HomeViewModel>: View {
    // MARK: - Variables
    @State private var showLogoutConfirmation: Bool = false
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

    func profileButton() -> some View {
        Button(
            action: {},
            label: {
                HStack {
                    Text("Tavo Profilis").frame(width: 120)
                    Image(systemName: "person.crop.circle.fill")
                }
            }
        )
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .tint(.black)
    }

    func logoutButton() -> some View {
        Button(
            action: { showLogoutConfirmation.toggle() },
            label: {
                HStack {
                    Text("Atsijungti").frame(width: 120)
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
            }
        )
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .tint(.black)
        .alert("Atsijungti", isPresented: $showLogoutConfirmation) {
            Button("Atšaukti", role: .cancel) {}
            Button("Atsijungti", role: .destructive) {
                interactor.onLogOutTap()
            }
        } message: {
            Text("Ar tikrai norite atsijungti?")
        }
    }

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: .sectionFooters) {
                    Section {
                        booksGridView()
                    } footer: {
                        Text(viewModel.title).font(.footnote)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading, content: logoutButton)
                ToolbarItem(placement: .topBarTrailing, content: profileButton)
            }
        }
        .animation(.bouncy, value: viewModel.isLoading)
        .animation(.bouncy, value: viewModel.books)
        .toolbarBackground(Constants.mainScreenColor, for: .navigationBar)
        .onAppear(perform: { [weak interactor] in interactor?.viewDidAppear() })
    }

    private func chipView(for book: HomeModels.BooksPresentable) -> some View {
        var isStartedReading: Bool {
            guard let readedPages = book.readedPages else { return false }
            return readedPages > 0
        }

        return Text(isStartedReading ? "Skaitoma" : "Nepradėta")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 1)
            .background(isStartedReading ? Color.green.gradient : Color.gray.gradient)
            .clipShape(Capsule())
    }

    private func booksGridView() -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]

        return ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.books) { book in
                    VStack(spacing: 8) {
                        chipView(for: book)

                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.brown.gradient.opacity(0.5))
                                .frame(width: 150, height: 200)

                            if let image = book.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 200)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                ProgressView()
                                    .frame(width: 150, height: 200)
                            }
                        }

                        Text(book.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity)

                        Spacer()

                        if let totalPages = book.totalPages {
                            let readedPages = book.readedPages ?? 0
                            HStack {
                                Spacer()
                                Text("\(readedPages) / \(totalPages) psl.")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.clear.opacity(0.5))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.brown.opacity(0.8), lineWidth: 2)
                    )
                    .onTapGesture { [weak interactor] in interactor?.onBookClicked(book.id) }
                }
            }
            .padding()
        }
    }
}
