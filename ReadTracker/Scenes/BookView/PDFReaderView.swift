import SwiftUI

struct PDFReaderView: View {
    let url: URL

    var body: some View {
        PDFKitView(url: url)
            .navigationTitle("PDF Viewer")
            .navigationBarTitleDisplayMode(.inline)
    }
}
