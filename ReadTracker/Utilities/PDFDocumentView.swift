import PDFKit
import SwiftUI

public struct PDFDocumentView: UIViewRepresentable {
    private let data: Data?
    private let url: URL?
    private let bottomGap: CGFloat?

    @Binding private var isOnLastPage: Bool

    // MARK: - Initializers
    public init(
        url: URL,
        isOnLastPage: Binding<Bool> = .constant(false),
        bottomGap: CGFloat? = nil
    ) {
        self.url = url
        self.data = nil
        self._isOnLastPage = isOnLastPage
        self.bottomGap = bottomGap
    }

    public init(
        _ data: Data,
        isOnLastPage: Binding<Bool> = .constant(false),
        bottomGap: CGFloat? = nil
    ) {
        self.url = nil
        self.data = data
        self._isOnLastPage = isOnLastPage
        self.bottomGap = bottomGap
    }

    // MARK: - UIViewRepresentable
    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true

        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)

        if let data {
            pdfView.document = PDFDocument(data: data)
        } else if let url {
            pdfView.document = PDFDocument(url: url)
        }

        context.coordinator.observer = NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: nil
        ) { [weak coordinator = context.coordinator] notification in
            coordinator?.pdfViewPageDidChange(notification)
        }

        if let bottomGap {
            DispatchQueue.main.async {
                if let scrollView = pdfView.subviews.compactMap({ $0 as? UIScrollView }).first {
                    scrollView.contentInset.bottom = bottomGap
                    scrollView.verticalScrollIndicatorInsets.bottom = bottomGap
                }
            }
        }

        return pdfView
    }

    public func updateUIView(_ uiView: PDFView, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(isOnLastPage: $isOnLastPage)
    }

    // MARK: - Coordinator
    public class Coordinator: NSObject {
        @Binding var isOnLastPage: Bool
        var observer: Any?

        init(isOnLastPage: Binding<Bool>) {
            self._isOnLastPage = isOnLastPage
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        @objc func pdfViewPageDidChange(_ notification: Notification) {
            guard
                let pdfView = notification.object as? PDFView,
                let document = pdfView.document,
                let currentPage = pdfView.currentPage
            else {
                return
            }

            let currentPageIndex = document.index(for: currentPage)
            let lastPageIndex = document.pageCount - 1
            isOnLastPage = (currentPageIndex == lastPageIndex)
        }
    }
}
