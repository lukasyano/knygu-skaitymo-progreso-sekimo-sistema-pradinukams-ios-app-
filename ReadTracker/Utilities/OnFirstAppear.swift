import SwiftUI

private struct OnFirstAppear: ViewModifier {
    let resetOnDisappear: Bool
    let action: () -> Void
    @State var isFirstAppear = true

    func body(content: Content) -> some View {
        content
            .onAppear(perform: {
                guard isFirstAppear else {
                    return
                }
                isFirstAppear = false
                action()
            })
            .onDisappear(perform: {
                guard resetOnDisappear else {
                    return
                }
                isFirstAppear = true
            })
    }
}

extension View {
    public func onFirstAppear(perform action: @escaping () -> Void, resetOnDisappear: Bool = false) -> some View {
        modifier(OnFirstAppear(resetOnDisappear: resetOnDisappear, action: action))
    }
}
