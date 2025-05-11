import PDFKit

struct ThumbnailGeneratorWorker {
    static func generate(from pdfURL: URL, size: CGSize = CGSize(width: 200, height: 300)) async -> UIImage? {
        guard let document = PDFDocument(url: pdfURL),
              let page = document.page(at: 0) else { return nil }
        
        return await MainActor.run {
            let thumbnail = page.thumbnail(of: size, for: .mediaBox)
            return thumbnail.jpegData(compressionQuality: 0.8).flatMap(UIImage.init)
        }
    }
}
