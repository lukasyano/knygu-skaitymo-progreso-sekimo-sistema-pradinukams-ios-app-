import SwiftUI

public extension View {
    /// Adds an action to perform shortly before an app leaves the background state on its way to becoming the active app.
    ///
    /// Uses `UIApplication.willEnterForegroundNotification`
    func onAppWillEnterForeground(perform action: @escaping () -> Void) -> some View {
        onLifecycleEvent({ $0.willEnterForegroundNotification }, perform: action)
    }

    /// Adds an action to perform when the app becomes active.
    ///
    /// Uses `UIApplication.didBecomeActiveNotification`
    func onAppDidBecomeActive(perform action: @escaping () -> Void) -> some View {
        onLifecycleEvent({ $0.didBecomeActiveNotification }, perform: action)
    }

    /// Adds an action to perform when the app is no longer active and loses focus.
    ///
    /// Uses `UIApplication.willResignActiveNotification`
    func onAppWillResignActive(perform action: @escaping () -> Void) -> some View {
        onLifecycleEvent({ $0.willResignActiveNotification }, perform: action)
    }
}

extension View {
    private func onLifecycleEvent(_ event: (UIApplication.Type) -> NSNotification.Name,
                                  perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: event(UIApplication.self)), perform: { _ in
            action()
        })
    }
}
