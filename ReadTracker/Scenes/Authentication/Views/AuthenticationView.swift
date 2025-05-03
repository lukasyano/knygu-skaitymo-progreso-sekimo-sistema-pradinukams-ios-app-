import Lottie
import SwiftUI

struct WarmGradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let background = LinearGradient(
            gradient: Gradient(colors: [
                .red,
                .yellow,
                .red
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )

        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(background)
            .cornerRadius(.infinity)
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
            .foregroundColor(.white)
            .font(.title2)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension View {
    func warmButtonStyle() -> some View {
        buttonStyle(WarmGradientButtonStyle())
    }
}

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
            .onAppear(perform: { [weak interactor] in interactor?.viewDidChange(.onAppear) })
    }

    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            VStack {
                LottieView(animation: .named("walkingDog.json")).looping()
                    .animationSpeed(0.9)
                    .frame(height: 500)

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
                .warmButtonStyle()
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}

#if DEBUG
    import Lottie
    import SwiftUI

    struct AuthenticationPreview: PreviewProvider {
        class MockAuthenticationInteractor: AuthenticationInteractor {
            func viewDidChange(_ type: ViewDidChangeType) {}
            func tapLogin() {}
            func tapRegister() {}
            static let mockInstance = MockAuthenticationInteractor()
        }

        struct PreviewContainer: View {
            var body: some View {
                NavigationView {
                    AuthenticationView(interactor: MockAuthenticationInteractor.mockInstance)
                }
            }
        }

        static var previews: some View {
            PreviewContainer()
        }
    }

#endif
