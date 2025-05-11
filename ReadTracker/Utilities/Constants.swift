import SwiftUI

enum Constants {
    static let mainScreenColor = Color.brown.opacity(0.3)
}

public extension Error {
    static var general: NSError {
        NSError(domain: "", code: -1)
    }
}
