import SwiftUI

extension Color {
    func darker(by percentage: CGFloat = 0.2) -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return Color(
            red: max(red - percentage, 0),
            green: max(green - percentage, 0),
            blue: max(blue - percentage, 0)
        )
    }
}

struct CustomProgressViewStyle: ProgressViewStyle {
    var height: CGFloat = 20
    var accentColor: Color = .green
    var isCompleted: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Fonas
                Capsule()
                    .frame(height: height)
                    .foregroundColor(accentColor.opacity(0.2))

                // Užpildas
                Capsule()
                    .frame(
                        width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                        height: height
                    )
                    // Jei užbaigta – ryškiai žalia, kitu atveju – tamsesnė akcento spalva
                    .foregroundColor(isCompleted ? accentColor : accentColor.darker(by: 0.2))
                    .animation(.easeInOut(duration: 0.4), value: configuration.fractionCompleted)

                // Overlay užbaigimo atveju: varnelė su tekstu
                if isCompleted {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: height * 0.8))
                        Text("Atlikta")
                            .font(.system(size: height * 0.5, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .frame(height: height)
    }
}

struct DailyProgressBar: View {
    var minutesRead: Int
    var goal: Int
    var height: CGFloat = 20

    private var progress: Double {
        goal > 0 ? Double(minutesRead) / Double(goal) : 0
    }

    var presentableMinutes: Int {
        if minutesRead > goal {
            return goal
        } else { return minutesRead }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Dienos skaitymo tikslas: \(presentableMinutes)/\(goal) min.")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.subheadline)

            ProgressView(value: progress)
                .progressViewStyle(
                    CustomProgressViewStyle(
                        height: height,
                        accentColor: .green,
                        isCompleted: progress >= 1.0
                    )
                )
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }
}
