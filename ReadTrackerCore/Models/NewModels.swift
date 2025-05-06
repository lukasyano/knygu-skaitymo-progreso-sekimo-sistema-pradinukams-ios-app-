//import SwiftData
//import UIKit
//import Foundation
//
//enum UserRole: String, Codable {
//    case parent, child
//}
//
//@Model
//final class User {
//    @Attribute(.unique) var id: String = UUID().uuidString
//    var role: UserRole
//    var name: String
//
//    // For parents: will hold their children
//    @Relationship(deleteRule: .cascade)
//    var children: [User] = []
//
//    // For children: points and a back–link to their parent
//    var totalPoints: Int = 0
//    @Relationship(deleteRule: .nullify)
//    var parent: User?
//
//    // For children: their reading progress entries
//    @Relationship(deleteRule: .cascade)
//    var progressEntries: [Progress] = []
//
//    init(role: UserRole, name: String) {
//        self.role = role
//        self.name = name
//    }
//}
//
//@Model
//final class Progress {
//    @Attribute(.unique) var id: String = UUID().uuidString
//    var pagesRead: Int
//    var totalPages: Int
//    var finished: Bool
//    var pointsEarned: Int
//
//    // Link back to the child and the book
//    @Relationship(deleteRule: .nullify)
//    var child: User?
//    @Relationship(deleteRule: .nullify)
//    var book: Book?
//
//    init(pagesRead: Int, totalPages: Int, finished: Bool, pointsEarned: Int) {
//        self.pagesRead = pagesRead
//        self.totalPages = totalPages
//        self.finished = finished
//        self.pointsEarned = pointsEarned
//    }
//}
//
