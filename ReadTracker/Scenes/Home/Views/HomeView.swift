import Combine
import Resolver
import SwiftData
import SwiftUI

struct HomeView<ViewModel: HomeViewModel>: View {
    // MARK: - Variables
    @State private var showLogoutConfirmation: Bool = false
    private unowned var interactor: HomeInteractor
    @ObservedObject private var viewModel: ViewModel
    let user: UserEntity

    // MARK: - Init
    init(
        interactor: HomeInteractor,
        viewModel: ViewModel,
        user: UserEntity
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
        self.user = user

        let role = user.role.rawValue

        _books = Query(
            filter: #Predicate<BookEntity> { $0.role == role },
            sort: \.title
        )
    }

    @Query private var books: [BookEntity]

    func profileButton() -> some View {
        Button(
            action: { [weak interactor] in interactor?.onProfileTap() },
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

            if books.isEmpty {
                LoadingView()
            } else {
                mainContentView
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading, content: logoutButton)
                        ToolbarItem(placement: .topBarTrailing, content: profileButton)
                    }
                    .animation(.easeInOut, value: books.isEmpty)
                    .animation(.bouncy, value: books)
                    .toolbarBackground(Constants.mainScreenColor, for: .navigationBar)
                    .onAppear(perform: { [weak interactor] in interactor?.viewDidAppear() })
            }
        }
    }

    private var mainContentView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16,
                pinnedViews: .sectionFooters
            ) {
                Section {
                    ForEach(books) { book in
                        BookItemView(
                            book: book,
                            user: user,
                            viewModel: viewModel,
                            interactor: interactor
                        )
                    }
                } footer: {
                    Text("Tavo bibliotekoje yra: \(books.count) knygų (-os)").font(.footnote)
                }
            }
        }
    }
}

private func chipView(pagesRead: Int) -> some View {
    let isStartedReading = pagesRead > 0

    return Text(isStartedReading ? "Skaitoma" : "Nepradėta")
        .frame(maxWidth: .infinity)
        .padding(.vertical, 1)
        .background(isStartedReading ? Color.mint.gradient.opacity(0.7) : Color.gray.gradient.opacity(0.7))
        .clipShape(Capsule())
}
