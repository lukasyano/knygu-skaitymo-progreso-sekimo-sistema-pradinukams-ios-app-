import SwiftUI

private enum ViewConstants {
    static let cornerRadius: CGFloat = 12
    static let fieldHeight: CGFloat = 52
}

struct LoginView<ViewModel: LoginViewModel>: View {
    // MARK: - Variables
    private unowned var interactor: LoginInteractor
    @ObservedObject private var viewModel: ViewModel
    @FocusState private var focusedField: FocusField?
    @State private var isPasswordVisible = false
    @State private var mockedChildCounter = 0
    enum FocusField {
        case email, password
    }

    // MARK: - Init
    init(interactor: LoginInteractor, viewModel: ViewModel) {
        self.interactor = interactor
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            contentView
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Demo") { [weak interactor] in
                    interactor?.onEmailChange(MockCredentials.childEmail(index: mockedChildCounter))
                    interactor?.onPasswordChange(MockCredentials.childPassword(index: mockedChildCounter))
                    mockedChildCounter += 1
                }
            }
        }
        .animation(.easeInOut, value: viewModel.isLoading)
        .onAppear(perform: { [weak interactor] in interactor?.viewDidAppear() })
        .onDisappear(perform: { [weak interactor] in interactor?.viewDidDisappear() })
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 40) {
                headerView
                inputFields
                actions
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)

            Text(viewModel.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }

    private var inputFields: some View {
        VStack(spacing: 24) {
            emailField
            passwordField
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Elektroninis paštas")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(focusedField == .email ? .blue : .secondary)

                TextField("name@example.com", text: .init(
                    get: { viewModel.email },
                    set: { [weak interactor] in interactor?.onEmailChange($0) }
                ))
                .focused($focusedField, equals: .email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
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
                    TextField("Įveskite slaptažodį", text: .init(
                        get: { viewModel.password },
                        set: { [weak interactor] in interactor?.onPasswordChange($0) }
                    ))
                } else {
                    SecureField("Įveskite slaptažodį", text: .init(
                        get: { viewModel.password },
                        set: { [weak interactor] in interactor?.onPasswordChange($0) }
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
            Button(action: login) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(viewModel.isDisabled ? "Negali būti tuščia !" : "Prisijungti")
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
        }
    }

    private func login() {
        focusedField = nil
        interactor.onLoginTap()
    }
}
