import PDFKit
import SwiftUI

public struct PDFDocumentView: UIViewRepresentable {
    private let url: URL
    @Binding private var isOnLastPage: Bool
    private var onPageChange: ((Int) -> Void)?

    // MARK: - Initializers
    public init(
        url: URL,
        isOnLastPage: Binding<Bool> = .constant(false),
        onPageChange: ((Int) -> Void)? = nil
    ) {
        self.url = url
        self._isOnLastPage = isOnLastPage
        self.onPageChange = onPageChange
    }

    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        pdfView.document = PDFDocument(url: url)

        context.coordinator.pdfView = pdfView
        context.coordinator.onPageChange = onPageChange

        context.coordinator.observer = NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: nil
        ) { [weak coordinator = context.coordinator] notification in
            coordinator?.pdfViewPageDidChange(notification)
        }

        return pdfView
    }

    public func updateUIView(_ uiView: PDFView, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(isOnLastPage: $isOnLastPage, onPageChange: onPageChange)
    }

    public class Coordinator: NSObject {
        @Binding var isOnLastPage: Bool
        var onPageChange: ((Int) -> Void)?
        var observer: Any?
        weak var pdfView: PDFView?

        init(isOnLastPage: Binding<Bool>, onPageChange: ((Int) -> Void)? = nil) {
            self._isOnLastPage = isOnLastPage
            self.onPageChange = onPageChange
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        @objc func pdfViewPageDidChange(_ notification: Notification) {
            guard
                let pdfView = pdfView,
                let document = pdfView.document,
                let currentPage = pdfView.currentPage
            else {
                return
            }

            let currentPageIndex = document.index(for: currentPage)
            let lastPageIndex = document.pageCount - 1
            isOnLastPage = (currentPageIndex == lastPageIndex)

            onPageChange?(currentPageIndex)
        }
    }
}
