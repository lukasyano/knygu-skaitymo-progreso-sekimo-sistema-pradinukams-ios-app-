import SwiftUI

private enum ViewConstants {

}

struct RegistrationView<ViewModel: RegistrationViewModel>: View {
    // MARK: - Variables
    @Environment(\.dismiss) private var dismiss
    private unowned var interactor: RegistrationInteractor
    @ObservedObject private var viewModel: ViewModel
    @FocusState private var focusedField: Bool

    // MARK: - Init

    init(
        interactor: RegistrationInteractor,
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
        .onAppear(perform: { [weak interactor] in interactor?.viewDidChange(.onAppear) })
        .onDisappear(perform: { [weak interactor] in interactor?.viewDidChange(.onDisappear) })
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

                Picker("Pasirinkite rolę", selection: .init(
                    get: { viewModel.roleSelection.selected },
                    set: { [weak interactor] in interactor?.onRoleChange($0) }
                )) {
                    ForEach(viewModel.roleSelection.availableRoles, id: \.self) { role in
                        Text(role.localized)
                    }
                }
                .pickerStyle(.segmented)

                Button(
                    action: { [weak interactor] in
                        focusedField = false
                        interactor?.onRegisterTap()
                    },
                    label: {
                        Text(viewModel.isDisabled ? "Negali būti tuščia !" : "Registruotis")
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
