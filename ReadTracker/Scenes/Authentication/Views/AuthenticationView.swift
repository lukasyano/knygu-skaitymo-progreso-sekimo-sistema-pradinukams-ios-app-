import Lottie
import SwiftUI

struct AuthenticationView: View {
    // MARK: - Variables
    private unowned var interactor: AuthenticationInteractor
    @State private var showRefreshAlert = false

    // MARK: - Init

    init(interactor: AuthenticationInteractor) {
        self.interactor = interactor
    }

    var body: some View {
        contentView
            .navigationTitle("Sveikas atvykęs!")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(
                        action: { [weak interactor] in interactor?.tapRegister() },
                        label: {
                            HStack(alignment: .bottom) {
                                Text("Registracija tėvams")
                                Image(systemName: "figure.and.child.holdinghands")
                            }
                        }
                    )
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle)
                    .tint(.black)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(
                            action: { showRefreshAlert.toggle() },
                            label: { Label("Perkrauti", systemImage: "books.vertical") }
                        )
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                    }
                    .tint(.gray)
                    .alert(
                        "Dėmesio",
                        isPresented: $showRefreshAlert,
                        actions: {
                            Button("Taip") { [weak interactor] in interactor?.tapReload() }
                            Button("Ne", role: .cancel) {}
                        },
                        message: {
                            Text("""
                            Šis veiksmas ištrins esamą knygų saugyklą ir užpildys ją iš naujo. \
                            Ar tikrai norite ištrinti ir perkrauti? Pastaba: tai yra atliekama \
                            automatiškai kartą per dieną.
                            """)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    )
                }
            }
            .onAppear(perform: { [weak interactor] in interactor?.viewDidAppear() })
    }

    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            VStack {
                LottieView(animation: .named("walkingDog.json")).looping()
                    .animationSpeed(0.9)
                    .frame(height: 600)

                Button(
                    action: { [weak interactor] in interactor?.tapLogin() },
                    label: { Text("Prisijungti") }
                )
                .warmButtonStyle()

                Spacer()
            }
        }
    }
}
