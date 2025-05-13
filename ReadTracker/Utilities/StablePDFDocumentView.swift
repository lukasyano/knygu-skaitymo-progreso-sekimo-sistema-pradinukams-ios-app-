import PDFKit
import SwiftUI

public struct StablePDFDocumentView: UIViewRepresentable {
    private let url: URL
    private let initialPageIndex: Int
    @Binding private var isOnLastPage: Bool
    private var onPageChange: ((Int) -> Void)?

    public init(
        url: URL,
        initialPageIndex: Int = 0,
        isOnLastPage: Binding<Bool> = .constant(false),
        onPageChange: ((Int) -> Void)? = nil
    ) {
        self.url = url
        self.initialPageIndex = initialPageIndex
        self._isOnLastPage = isOnLastPage
        self.onPageChange = onPageChange
    }

    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        configurePDFView(pdfView, context: context)
        loadDocument(pdfView: pdfView, context: context)
        return pdfView
    }

    public func updateUIView(_ uiView: PDFView, context: Context) {
        if context.coordinator.lastKnownPageIndex != initialPageIndex {
            DispatchQueue.main.async {
                goToPage(uiView, pageIndex: initialPageIndex, context: context)
            }
        }
    }

    private func goToPage(_ pdfView: PDFView, pageIndex: Int, context: Context) {
        guard let document = pdfView.document else { return }
        let safeIndex = min(max(pageIndex, 0), document.pageCount - 1)
        guard let page = document.page(at: safeIndex) else { return }
        pdfView.go(to: page)
        context.coordinator.lastKnownPageIndex = safeIndex
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            initialPageIndex: initialPageIndex,
            isOnLastPage: $isOnLastPage,
            onPageChange: onPageChange
        )
    }
}

// MARK: - Configuration
private extension StablePDFDocumentView {
    func configurePDFView(_ pdfView: PDFView, context: Context) {
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
        pdfView.pageShadowsEnabled = false
        pdfView.interpolationQuality = .low
        pdfView.backgroundColor = .clear

        context.coordinator.pdfView = pdfView
        setupPageChangeObserver(context.coordinator)
    }

    private func loadDocument(pdfView: PDFView, context: Context) {
        if pdfView.document != nil { return }

        DispatchQueue.global(qos: .userInitiated).async {
            if let document = PDFDocument(url: self.url) {
                DispatchQueue.main.async {
                    if pdfView.document == nil {
                        pdfView.document = document
                        self.goToInitialPage(pdfView: pdfView, document: document, context: context)
                    }
                }
            }
        }
    }

    private func goToInitialPage(pdfView: PDFView, document: PDFDocument, context: Context) {
        let pageIndex = min(initialPageIndex, document.pageCount - 1)
        guard let page = document.page(at: pageIndex) else { return }
        pdfView.go(to: page)
        context.coordinator.lastKnownPageIndex = pageIndex
        updateInitialPageState(pdfView: pdfView, document: document, context: context)
    }

    private func updateInitialPageState(pdfView: PDFView, document: PDFDocument, context: Context) {
        guard let currentPage = pdfView.currentPage else {
            isOnLastPage = false
            onPageChange?(0)
            return
        }

        let currentPageIndex = document.index(for: currentPage)
        let lastPageIndex = document.pageCount - 1

        isOnLastPage = currentPageIndex == lastPageIndex
        onPageChange?(currentPageIndex)
        context.coordinator.lastKnownPageIndex = currentPageIndex
    }

    func setupPageChangeObserver(_ coordinator: Coordinator) {
        coordinator.observer = NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: nil,
            queue: .main
        ) { [weak coordinator] notification in
            coordinator?.pdfViewPageDidChange(notification)
        }
    }
}

// MARK: - Coordinator
public extension StablePDFDocumentView {
    class Coordinator: NSObject {
        private let initialPageIndex: Int
        @Binding private var isOnLastPage: Bool
        var onPageChange: ((Int) -> Void)?
        var observer: Any?
        weak var pdfView: PDFView?
        var lastKnownPageIndex: Int = 0

        init(
            initialPageIndex: Int,
            isOnLastPage: Binding<Bool>,
            onPageChange: ((Int) -> Void)?
        ) {
            self.initialPageIndex = initialPageIndex
            self._isOnLastPage = isOnLastPage
            self.onPageChange = onPageChange
            self.lastKnownPageIndex = initialPageIndex
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
            pdfView?.document = nil
            pdfView?.removeFromSuperview()
        }

        @objc func pdfViewPageDidChange(_ notification: Notification) {
            guard let pdfView = pdfView,
                  let document = pdfView.document,
                  let currentPage = pdfView.currentPage else { return }

            let currentPageIndex = document.index(for: currentPage)
            let lastPageIndex = document.pageCount - 1

            if currentPageIndex != lastKnownPageIndex {
                isOnLastPage = currentPageIndex == lastPageIndex
                onPageChange?(currentPageIndex)
                lastKnownPageIndex = currentPageIndex
            }
        }
    }
}
