import SwiftUI

extension View {
    public func clearModalBackground() -> some View {
        self.modifier(ClearBackgroundViewModifier())
    }
}
