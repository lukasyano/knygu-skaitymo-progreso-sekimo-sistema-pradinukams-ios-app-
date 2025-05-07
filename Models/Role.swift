import SwiftData

enum Role: String, CaseIterable, Codable {
    case parent
    case child
    case unknown
    
    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "parent": self = .parent
        case "child": self = .child
        default: self = .unknown
        }
    }
}

extension Role {
    var localized: String {
        switch self {
        case .parent:
            "Tėvas"
        case .child:
            "Vaikas"
        case .unknown:
            ""
        }
    }
}
