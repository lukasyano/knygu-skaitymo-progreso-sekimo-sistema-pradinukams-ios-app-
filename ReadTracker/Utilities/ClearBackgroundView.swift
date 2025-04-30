import SwiftUI

public struct ClearBackgroundView: UIViewRepresentable {
    public func makeUIView(context _: Context) -> some UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    public func updateUIView(_: UIViewType, context _: Context) {}
}
