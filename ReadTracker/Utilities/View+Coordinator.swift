import SwiftUI

extension View {
    func presentedView<Item: Identifiable & Equatable, Content: View>(
        _ item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        fullScreenCover(
            item: item,
            onDismiss: { item.wrappedValue = nil },
            content: content
        )
    }
}
