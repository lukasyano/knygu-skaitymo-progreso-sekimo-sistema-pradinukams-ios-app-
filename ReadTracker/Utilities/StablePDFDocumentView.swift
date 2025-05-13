import PDFKit
import SwiftUI

struct StablePDFDocumentView: UIViewRepresentable {
    private let url: URL
    private let initialPageIndex: Int
    @Binding private var isOnLastPage: Bool
    private var onPageChange: ((Int) -> Void)?
    private var role: Role
    @ObservedObject private var soundPlayer = DefaultSoundPlayer()

    init(
        url: URL,
        initialPageIndex: Int = 0,
        isOnLastPage: Binding<Bool> = .constant(false),
        onPageChange: ((Int) -> Void)? = nil,
        role: Role
    ) {
        self.url = url
        self.initialPageIndex = initialPageIndex
        self._isOnLastPage = isOnLastPage
        self.onPageChange = onPageChange
        self.role = role
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
            onPageChange: onPageChange,
            role: role, soundPlayer: soundPlayer
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

        DispatchQueue.main.async {
            for findAllSubview in pdfView.findAllSubviews(ofType: UIScrollView.self) {
                findAllSubview.showsHorizontalScrollIndicator = false
                findAllSubview.showsVerticalScrollIndicator = false
            }
        }

        if role == .child {
            pdfView.isUserInteractionEnabled = false
        }

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
extension StablePDFDocumentView {
    class Coordinator: NSObject {
        private let initialPageIndex: Int
        @Binding private var isOnLastPage: Bool
        var onPageChange: ((Int) -> Void)?
        let role: Role
        var soundPlayer: SoundPlayer?

        var observer: Any?
        weak var pdfView: PDFView?
        var lastKnownPageIndex: Int = 0

        init(
            initialPageIndex: Int,
            isOnLastPage: Binding<Bool>,
            onPageChange: ((Int) -> Void)?,
            role: Role,
            soundPlayer: SoundPlayer?
        ) {
            self.initialPageIndex = initialPageIndex
            self._isOnLastPage = isOnLastPage
            self.onPageChange = onPageChange
            self.lastKnownPageIndex = initialPageIndex
            self.role = role
            self.soundPlayer = soundPlayer
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

            if role == .child {
                soundPlayer?.playPageFlipSound()
            }
        }
    }
}

extension UIView {
    func findAllSubviews<T: UIView>(ofType type: T.Type) -> [T] {
        var results = [T]()
        for subview in subviews {
            results += subview.findAllSubviews(ofType: type)
            if let subview = subview as? T {
                results.append(subview)
            }
        }
        return results
    }
}
