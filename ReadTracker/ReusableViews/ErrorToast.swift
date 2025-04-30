import SwiftUI

struct ErrorToast: View {
    let message: String
    var delay: Double = 4.0
    var dismiss: () -> Void = {}

    @State private var dismissTask: DispatchWorkItem?

    var body: some View {
        Text(message)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.red.gradient)
            .cornerRadius(12)
            .shadow(radius: 5)
            .overlay(
                Button(
                    action: {
                        dismissTask?.cancel()
                        dismiss()
                    },
                    label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black)
                            .padding(-8)
                    }
                ),
                alignment: .topTrailing
            )
            .onAppear {
                let task = DispatchWorkItem {
                    dismiss()
                }
                dismissTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
            }
            .onDisappear {
                dismissTask?.cancel()
            }
    }
}

#Preview {
    ErrorToast(message: "Naudokite stipresnį slaptažodį (min. 6 simboliai)!")
}
