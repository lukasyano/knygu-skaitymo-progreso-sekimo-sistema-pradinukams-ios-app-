import SwiftUI
import UIKit

struct HoldToDismissButton: View {
    let action: () -> Void
    let holdDuration: Double = 1.5

    @State private var isPressing = false
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack(alignment: .leading) {
            // Background track
            Capsule()
                .fill(Color.black.opacity(0.8))
                .frame(width: 300, height: 50)

            // Progress fill
            Capsule()
                .fill(progress < 1.0 ? Color.blue : Color.green)
                .frame(width: 300 * progress, height: 50)
                .animation(.linear(duration: 0.1), value: progress)

            // Button label
            HStack {
                Spacer()
                Text(isPressing ? "Laikykite ilgiau" : "Baigti skaitymą")
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
            }
            .frame(width: 300, height: 50)
        }
        .sensoryFeedback(.error, trigger: isPressing)
        .contentShape(Rectangle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: holdDuration)
                .onChanged { _ in handlePressStart() }
                .onEnded { _ in handlePressEnd(success: true) }
        )
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in handlePressEnd(success: false) }
        )
    }

    private func handlePressStart() {
        guard !isPressing else { return }

        isPressing = true

        // Start progress animation
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            progress += 0.05 / holdDuration
            if progress >= 1.0 {
                handlePressEnd(success: true)
            }
        }
    }

    private func handlePressEnd(success: Bool) {
        timer?.invalidate()
        timer = nil

        if success {
            action()
        }

        withAnimation(.spring()) {
            progress = 0
            isPressing = false
        }
    }
}
