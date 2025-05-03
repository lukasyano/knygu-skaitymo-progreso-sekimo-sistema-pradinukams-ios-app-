public struct None: Equatable, Identifiable {
    public let id = 0
    
    public static var none: None { None() }
}
