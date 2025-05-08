import SwiftUI

struct ProfileView<ViewModel: ProfileViewModel>: View {
    // MARK: - Variables
    @Environment(\.dismiss) private var dismiss
    private unowned var interactor: ProfileInteractor
    @ObservedObject private var viewModel: ViewModel

    init(
        interactor: ProfileInteractor,
        viewModel: ViewModel
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
    }

    private var progressGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
            ForEach(viewModel.progressData) { progress in
                progressCard(for: progress)
            }
        }
    }

    private func progressCard(for progress: ProgressData) -> some View {
        let progressValue = progress.totalPages > 0 ?
            CGFloat(progress.pagesRead) / CGFloat(progress.totalPages) : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(progress.bookId)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Image(systemName: progress.finished ? "checkmark.circle.fill" : "book.fill")
                    .foregroundColor(progress.finished ? .green : .orange)
            }

            // Dynamic-width progress bar
            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    Capsule()
                        .frame(height: 6)
                        .foregroundColor(Color(.systemFill))

                    Capsule()
                        .frame(width: geo.size.width * progressValue, height: 6)
                        .foregroundColor(progress.finished ? .green : .blue)
                        .animation(.spring, value: progressValue)
                }
                .frame(height: 6)
            }

            HStack {
                Text("\(progress.pagesRead)/\(progress.totalPages) psl.")
                    .font(.caption)

                Spacer()

                Text("\(progress.pointsEarned) taškų")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var emptyProgressView: some View {
        VStack {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Text("Nėra progreso duomenų")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var completedBooksCount: Int {
        viewModel.progressData.filter { $0.finished }.count
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Skaitymo progresas")
                    .font(.subheadline)
                    .foregroundColor(.purple)

                Spacer()

                if !viewModel.progressData.isEmpty {
                    Text("\(completedBooksCount) iš \(viewModel.progressData.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.progressData.isEmpty {
                emptyProgressView
            } else {
                progressGrid
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mano vaikai")
                    .font(.subheadline)
                    .foregroundColor(.green)

                Spacer()

                Button {
                    viewModel.isUserCreationActive = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }

            if viewModel.childs.isEmpty {
                Text("Nėra pridėtų vaikų")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.childs) { child in
                        ChildRow(child: child)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }

    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vartotojo informacija")
                .font(.subheadline)
                .foregroundColor(.blue)

            InfoRow(label: "Vardas", value: viewModel.user.name)
            InfoRow(label: "El. paštas", value: viewModel.user.email)
            InfoRow(label: "Rolė", value: viewModel.user.role.localized)

            if viewModel.user.role == .child {
                InfoRow(label: "Taškai", value: viewModel.user.totalPoints.formatted())
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        userInfoSection

                        if viewModel.user.role == .child {
                            progressSection
                        }

                        if viewModel.user.role == .parent {
                            childrenSection
                        }
                    }
                    .padding()
                }
                .navigationTitle("Profilis")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Uždaryti") {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $viewModel.isUserCreationActive) {
                    CreateChildView(isLoading: $viewModel.isLoading) { [weak interactor] name, email, password in
                        interactor?.createChild(name: name, email: email, password: password)
                    }
                }
            }
        }
        .onAppear { [weak interactor] in interactor?.viewDidAppear() }
        .animation(.spring, value: viewModel.childs)
        .animation(.easeInOut, value: viewModel.isLoading)
    }
}
