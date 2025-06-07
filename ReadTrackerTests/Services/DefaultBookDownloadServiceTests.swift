import Combine
import Foundation
import PDFKit
@testable import ReadTracker
import SwiftData
import XCTest

final class DefaultBookDownloadServiceTests: XCTestCase {
    private var service: DefaultBookDownloadService!
    private var modelContext: ModelContext!
    private var container: ModelContainer!
    private var tempBooksDir: URL!

    override func setUp() {
        super.setUp()

        do {
            let schema = Schema([BookEntity.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: schema, configurations: config)
            modelContext = ModelContext(container)

            tempBooksDir = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(
                at: tempBooksDir,
                withIntermediateDirectories: true
            )

            service = DefaultBookDownloadService(
                modelContext: modelContext,
                booksDirectory: tempBooksDir
            )
        } catch {
            XCTFail("Setup failed: \(error)")
        }
    }

    override func tearDown() {
        do {
            let attributes: [FileAttributeKey: Any] = [.posixPermissions: 0o777]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: tempBooksDir.path)
            try FileManager.default.removeItem(at: tempBooksDir)
        } catch {
            XCTFail("Cleanup failed: \(error)")
        }
        super.tearDown()
    }

    func test_skipsExistingDownload() throws {
        // Setup
        let testPDF = try createTestPDF()
        let existingFile = tempBooksDir.appendingPathComponent("\(testPDF.sha256).pdf")
        try testPDF.data.write(to: existingFile)

        let entity = BookEntity(
            id: UUID().uuidString,
            title: "Existing",
            role: "Reader",
            pdfURL: testPDF.url.absoluteString,
            fileURL: existingFile
        )
        modelContext.insert(entity)

        // Execute
        let exp = expectation(description: "Download completes")
        var receivedError: Error?

        service.downloadMissingBooks()
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                    }
                    exp.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1)

        // Verify
        XCTAssertNil(receivedError)
        XCTAssertEqual(entity.fileURL, existingFile)
    }

    func test_handlesDownloadErrors() throws {
        // Setup
        let invalidEntity = BookEntity(id: UUID().uuidString, title: "Invalid", role: "Reader", pdfURL: "invalid url")
        modelContext.insert(invalidEntity)

        // Execute
        let exp = expectation(description: "Download fails")
        var receivedError: Error?

        service.downloadMissingBooks()
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                        exp.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        wait(for: [exp], timeout: 10)

        // Verify
        XCTAssertNotNil(receivedError)
    }

    // MARK: - clearLocalFiles Tests

    func test_clearsFiles() throws {
        // Setup
        let file1 = tempBooksDir.appendingPathComponent("test1.pdf")
        let file2 = tempBooksDir.appendingPathComponent("test2.pdf")
        try "dummy".write(to: file1, atomically: true, encoding: .utf8)
        try "dummy".write(to: file2, atomically: true, encoding: .utf8)

        // Execute
        let exp = expectation(description: "Clear completes")
        var receivedError: Error?

        service.clearLocalFiles()
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                    }
                    exp.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1)

        // Verify
        XCTAssertNil(receivedError)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file1.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file2.path))
    }

    func test_handlesClearErrors() throws {
        // Setup - Make directory read-only to cause error
        let attributes: [FileAttributeKey: Any] = [.posixPermissions: 0o444]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: tempBooksDir.path)

        // Execute
        let exp = expectation(description: "Clear fails")
        var receivedError: Error?

        service.clearLocalFiles()
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                        exp.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1)

        // Verify
        XCTAssertNotNil(receivedError)
    }

    // MARK: - Helpers

    private var cancellables = Set<AnyCancellable>()

    private func createTestPDF() throws -> (url: URL, data: Data, sha256: String) {
        let data = try XCTUnwrap(UIImage(systemName: "star")?.pdfData())
        let sha256 = data.sha256String
        let url = URL(string: "https://test.com/\(UUID().uuidString).pdf")!
        return (url, data, sha256)
    }
}

// MARK: - Safe PDF Generation
extension UIImage {
    func pdfData() -> Data? {
        let pdfData = NSMutableData()
        let bounds = CGRect(origin: .zero, size: size)

        // Safe PDF context creation
        UIGraphicsBeginPDFContextToData(pdfData, bounds, nil)
        UIGraphicsBeginPDFPage()

        // Draw image in current context
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.saveGState()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(cgImage!, in: bounds)
        context.restoreGState()

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
}
