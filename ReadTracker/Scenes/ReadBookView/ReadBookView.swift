import SwiftUI

struct ReadBookView: View {
    let url: URL
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    private func dismiss() { presentationMode.wrappedValue.dismiss() }

    var body: some View {
        ZStack(alignment: .bottom) {
            PDFDocumentView(url: url)
                .edgesIgnoringSafeArea(.all)

            HoldToDismissButton(action: dismiss)
                .padding(.bottom, 10)
                .padding(.horizontal, 30)
        }
    }
}
