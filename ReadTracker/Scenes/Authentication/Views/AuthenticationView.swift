import SwiftUI

private enum ViewConstants {}

struct AuthenticationView: View {
    // MARK: - Variables
    private unowned var interactor: AuthenticationInteractor

    // MARK: - Init

    init(interactor: AuthenticationInteractor) {
        self.interactor = interactor
    }

    var body: some View {
        contentView
            .navigationTitle("Prisijungimo būdai")
    }

    @ViewBuilder
    private var contentView: some View {
        VStack {
            Group {
                Button(
                    action: { [weak interactor] in interactor?.tapLogin() },
                    label: { Text("Prisijungti") }
                )
                Button(
                    action: { [weak interactor] in interactor?.tapRegister() },
                    label: { Text("Registruotis") }
                )
            }
            .buttonStyle(.bordered)
        }
    }
}
