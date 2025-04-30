import SwiftUI

extension View {
    public func navigation<Item, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: (Item) -> Destination
    ) -> some View {
        navigationDestination(
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { value in
                    if !value {
                        item.wrappedValue = nil
                    }
                }
            ),
            destination: { item.wrappedValue.map(destination) }
        )
    }
}
