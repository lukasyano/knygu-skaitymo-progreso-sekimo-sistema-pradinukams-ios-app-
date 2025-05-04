import UIKit

enum HomeModels {
    struct BooksPresentable: Identifiable {
        let id: String
        let title: String
        let readedPages: Int?
        let totalPages: Int?
        let image: UIImage?
    }
    
    struct BookProgressPreseentable: Identifiable {
        let id: String
        let readedPages: Int
    }
}
