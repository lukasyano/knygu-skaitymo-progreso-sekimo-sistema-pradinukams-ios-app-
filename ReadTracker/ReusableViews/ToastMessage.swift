import Combine
import SwiftUI

struct ToastMessage: View {
    enum ToastState: Equatable {
        case info, error
        case custom(Color)
    }

    let message: String
    var delay: Double = 4.0
    var dismiss: () -> Void = {}
    var toastState: ToastState

    private var backgroundColor: Color {
        switch toastState {
        case .info: return .green
        case .error: return .red
        case let .custom(color): return color
        }
    }

    @State private var remainingTime: Double = 0
    @State private var dismissTask: DispatchWorkItem?
    @State private var timerSubscription: Cancellable?

    private func cancelButton() -> some View {
        Button(
            action: {
                dismiss()
                dismissTask?.cancel()
                timerSubscription?.cancel()
            },
            label: {
                Image(systemName:
                    toastState == .info ?
                        "checkmark.circle.fill" :
                        "xmark.circle.fill"
                )
                .font(.title)
                .foregroundStyle(.white, .black)
                .contentShape(Rectangle())
            }
        )
        .padding(2)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ProgressView(value: remainingTime, total: delay)
                    .progressViewStyle(LinearProgressViewStyle(tint: .primary))
                    .frame(height: 2)
                    .animation(.linear(duration: 0.016), value: remainingTime)

                Text("\(Int(ceil(remainingTime)))s")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Text(message)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(backgroundColor.gradient)
        .cornerRadius(12)
        .shadow(radius: 5)
        .buttonStyle(PlainButtonStyle())
        .padding()
        .overlay(alignment: .topTrailing, content: cancelButton)
        .onAppear {
            remainingTime = delay

            // Schedule automatic dismissal
            let task = DispatchWorkItem {
                timerSubscription?.cancel()
                dismiss()
            }
            dismissTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)

            // Start timer to update remainingTime
            timerSubscription = Timer.publish(every: 0.016, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    guard remainingTime > 0 else {
                        timerSubscription?.cancel()
                        remainingTime = 0
                        return
                    }
                    remainingTime = max(remainingTime - 0.016, 0)
                }
        }
        .onDisappear {
            dismissTask?.cancel()
            timerSubscription?.cancel()
        }
    }
}

#Preview {
    ToastMessage(message: "Naudokite stipresnį slaptažodį (min. 6 simboliai)!", toastState: .error)
}
