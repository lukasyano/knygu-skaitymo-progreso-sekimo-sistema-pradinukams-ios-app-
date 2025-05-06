import SwiftData

@MainActor
final class DataConfiguration {
    static let shared = DataConfiguration()

    let container: ModelContainer
    let context: ModelContext

    private init() {
        let schema = Schema([BookEntity.self])
        let config = ModelConfiguration("Books", schema: schema)
        do {
            self.container = try ModelContainer(for: schema, configurations: config)
            self.context = ModelContext(container)
            context.autosaveEnabled = true
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }
}
