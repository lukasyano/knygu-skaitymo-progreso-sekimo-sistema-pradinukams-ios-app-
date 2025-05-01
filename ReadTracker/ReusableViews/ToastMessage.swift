import SwiftUI
import Combine

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
    @StateObject private var timerManager = TimerManager()

    private func cancelButton() -> some View {
        Button(
            action: {
                cancelToast()
            },
            label: {
                Image(systemName: toastState == .info ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white, .black)
                    .contentShape(Rectangle())
            }
        )
        .padding(2)
    }

    private func cancelToast() {
        dismissTask?.cancel()
        timerManager.cancel()
        dismiss()
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

            // Cancel after delay
            let task = DispatchWorkItem {
                timerManager.cancel()
                dismiss()
            }
            dismissTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)

            // Start timer
            timerManager.start(interval: 0.016) {
                if remainingTime > 0 {
                    remainingTime = max(remainingTime - 0.016, 0)
                }
            }
        }
        .onDisappear {
            cancelToast()
        }
    }
}

final class TimerManager: ObservableObject {
    private var subscription: AnyCancellable?

    func start(interval: TimeInterval, tick: @escaping () -> Void) {
        subscription = Timer
            .publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in tick() }
    }

    func cancel() {
        subscription?.cancel()
        subscription = nil
    }
}
