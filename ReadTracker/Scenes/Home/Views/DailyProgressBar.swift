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
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(height: height)
                    .foregroundColor(accentColor.opacity(0.2))

                Capsule()
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: height)
                    .foregroundColor(isCompleted ? .blue : accentColor.darker(by: 0.2))
            }
        }
    }
}

struct DailyProgressBar: View {
    var minutesRead: Int
    var goal: Int
    var height: CGFloat = 20

    private var progress: Double {
        goal > 0 ? Double(minutesRead) / Double(goal) : 0
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Dienos skaitymo tikslas: \(minutesRead)/\(goal) min.")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.subheadline)

            ProgressView(value: progress)
                .progressViewStyle(CustomProgressViewStyle(height: height, isCompleted: progress >= 1.0))
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
        .padding(.vertical, 8)
    }
}
