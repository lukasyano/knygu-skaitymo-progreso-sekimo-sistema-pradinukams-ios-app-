import SwiftUI

struct RegistrationView<ViewModel: RegistrationViewModel>: View {
    // MARK: - Variables
    @Environment(\.dismiss) private var dismiss
    private unowned var interactor: RegistrationInteractor
    @ObservedObject private var viewModel: ViewModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, email, password
    }

    init(
        interactor: RegistrationInteractor,
        viewModel: ViewModel
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            if viewModel.isLoading {
                LoadingView()
            } else {
                NavigationView {
                    formContent()
                        .navigationTitle(viewModel.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .onAppear { [weak interactor] in interactor?.viewDidAppear() }
                }
            }
        }
        .animation(.easeInOut, value: viewModel.isLoading)
    }

    @ViewBuilder
    private func formContent() -> some View {
        Form {
            Section(header: Text("Paskyros informacija")) {
                TextField("Vardas", text: .init(
                    get: { viewModel.name },
                    set: { interactor.onNameChange($0) }
                ))
                .focused($focusedField, equals: .name)
                .textContentType(.name)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)

                TextField("El. paštas", text: .init(
                    get: { viewModel.email },
                    set: { interactor.onEmailChange($0) }
                ))
                .keyboardType(.emailAddress)
                .focused($focusedField, equals: .email)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)

                SecureField("Slaptažodis", text: .init(
                    get: { viewModel.password },
                    set: { interactor.onPasswordChange($0) }
                ))
                .focused($focusedField, equals: .password)
                .textContentType(.newPassword)
            }
            Section {
                Button {
                    focusedField = nil
                    interactor.onRegisterTap()
                } label: {
                    HStack {
                        Spacer()
                        Text("Registruotis")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(viewModel.isDisabled)
            } footer: {
                if viewModel.isDisabled {
                    Text("Užpildykite visus laukus.")
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
        }
    }
}
