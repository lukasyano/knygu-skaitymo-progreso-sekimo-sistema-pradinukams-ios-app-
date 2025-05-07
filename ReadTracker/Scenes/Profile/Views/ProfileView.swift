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

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mano vaikai")
                    .font(.headline)
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
                .font(.headline)
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
