import SwiftUI

public struct ClearBackgroundViewModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content.background(ClearBackgroundView())
    }
}
