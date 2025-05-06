import SwiftUI

private enum ViewConstants {}

struct LoginView<ViewModel: LoginViewModel>: View {
    // MARK: - Variables

    @Environment(\.dismiss) private var dismiss
    private unowned var interactor: LoginInteractor
    @ObservedObject private var viewModel: ViewModel
    @FocusState private var focusedField: Bool

    // MARK: - Init

    init(
        interactor: LoginInteractor,
        viewModel: ViewModel
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                LoadingView()
            } else {
                contentView
            }
        }
        .animation(.bouncy, value: viewModel.isLoading)
        .onAppear(perform: { [weak interactor] in interactor?.viewDidAppear() })
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack {
                Text(viewModel.title)
                Group {
                    TextField("El. paštas", text: .init(
                        get: { viewModel.email },
                        set: { [weak interactor] in interactor?.onEmailChange($0) }
                    ))

                    SecureField("Slaptažodis", text: .init(
                        get: { viewModel.password },
                        set: { [weak interactor] in interactor?.onPasswordChange($0) }
                    ))
                }
                .textFieldStyle(.roundedBorder)
                .focused($focusedField)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)

                HStack {
                    Button(
                        action: { [weak interactor] in interactor?.onRememberMeToggle() },
                        label: {
                            Image(systemName: viewModel.rememberMe ? "checkmark.square" : "square")
                                .foregroundColor(.accentColor)
                            Text("Prisiminti mane")
                        }
                    )
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(
                    action: { [weak interactor] in
                        focusedField = false
                        interactor?.onLoginTap()
                    },
                    label: {
                        Text(viewModel.isDisabled ? "Negali būti tuščia !" : "Prisijungti")
                            .frame(maxWidth: .infinity)
                    }
                )
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isDisabled)
                .padding()
            }
            .padding()
        }
    }
}
