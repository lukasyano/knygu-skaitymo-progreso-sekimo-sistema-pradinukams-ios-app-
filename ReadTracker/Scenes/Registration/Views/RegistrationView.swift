import SwiftUI

private enum ViewConstants {
    static let cornerRadius: CGFloat = 12
    static let fieldHeight: CGFloat = 52
}

struct RegistrationView<ViewModel: RegistrationViewModel>: View {
    // MARK: - Variables
    @Environment(\.dismiss) private var dismiss
    private unowned var interactor: RegistrationInteractor
    @ObservedObject private var viewModel: ViewModel
    @FocusState private var focusedField: Field?
    @State private var isPasswordVisible = false
    @State private var mockedParentCounter = 0

    enum Field: Hashable {
        case name, email, password
    }

    // MARK: - Init
    init(interactor: RegistrationInteractor, viewModel: ViewModel) {
        self.interactor = interactor
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            contentView
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Demo") { [weak interactor] in

                            interactor?.onNameChange(MockCredentials.name(index: mockedParentCounter))
                            interactor?.onEmailChange(MockCredentials.email(index: mockedParentCounter))
                            interactor?.onPasswordChange(MockCredentials.password(index: mockedParentCounter))
                            mockedParentCounter += 1
                        }
                    }
                }
        }
        .animation(.easeInOut, value: viewModel.isLoading)
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 40) {
                headerView
                inputFields
                actions
                footer
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)

            Text(viewModel.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }

    private var inputFields: some View {
        VStack(spacing: 24) {
            nameField
            emailField
            passwordField
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Vardas")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "person")
                    .foregroundColor(focusedField == .name ? .blue : .secondary)

                TextField("Įveskite savo vardą", text: .init(
                    get: { viewModel.name },
                    set: { interactor.onNameChange($0) }
                ))
                .focused($focusedField, equals: .name)
                .textContentType(.name)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
            }
            .padding()
            .frame(height: ViewConstants.fieldHeight)
            .background(
                RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                    .strokeBorder(focusedField == .name ? .blue : .gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("El. paštas")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(focusedField == .email ? .blue : .secondary)

                TextField("pavyzdys@example.com", text: .init(
                    get: { viewModel.email },
                    set: { interactor.onEmailChange($0) }
                ))
                .focused($focusedField, equals: .email)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
            }
            .padding()
            .frame(height: ViewConstants.fieldHeight)
            .background(
                RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                    .strokeBorder(focusedField == .email ? .blue : .gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Slaptažodis")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "lock")
                    .foregroundColor(focusedField == .password ? .blue : .secondary)

                if isPasswordVisible {
                    TextField("Sukurkite slaptažodį", text: .init(
                        get: { viewModel.password },
                        set: { interactor.onPasswordChange($0) }
                    ))
                } else {
                    SecureField("Sukurkite slaptažodį", text: .init(
                        get: { viewModel.password },
                        set: { interactor.onPasswordChange($0) }
                    ))
                }

                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(height: ViewConstants.fieldHeight)
            .background(
                RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                    .strokeBorder(focusedField == .password ? .blue : .gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 16) {
            Button(action: register) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Registruotis")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: ViewConstants.fieldHeight)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(ViewConstants.cornerRadius)
                .shadow(radius: 4)
            }
            .disabled(viewModel.isDisabled)

            if viewModel.isDisabled {
                Text("Užpildykite visus laukus teisingai.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Jau turite paskyrą?")
                Button("Prisijungti") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
        }
        .font(.callout)
    }

    private func register() {
        focusedField = nil
        interactor.onRegisterTap()
    }
}
