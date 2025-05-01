public enum Role: String, CaseIterable {
    case parent
    case child
    case unknown
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
