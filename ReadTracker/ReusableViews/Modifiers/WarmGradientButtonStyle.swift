import SwiftUI

struct WarmGradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PulsatingButton(configuration: configuration)
    }

    private struct PulsatingButton: View {
        let configuration: Configuration
        @State private var pulsate = false

        var body: some View {
            let background = LinearGradient(
                gradient: Gradient(colors: [.red, .yellow, .red]),
                startPoint: .leading,
                endPoint: .trailing
            )

            configuration.label
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(background.opacity(0.9))
                .cornerRadius(50)
                .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
                .scaleEffect(pulsate ? 1.05 : 0.95)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: pulsate
                )
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
                .foregroundColor(.white)
                .font(.title)
                .sensoryFeedback(.selection, trigger: configuration.isPressed)
                .onAppear {
                    pulsate = true
                }
        }
    }
}

extension View {
    func warmButtonStyle() -> some View {
        buttonStyle(WarmGradientButtonStyle())
    }
}
