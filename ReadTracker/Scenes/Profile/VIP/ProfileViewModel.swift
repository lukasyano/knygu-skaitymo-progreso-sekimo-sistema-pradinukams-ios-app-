import SwiftUI

protocol ProfileDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayUser(_ user: UserEntity)
    func displayChilds(_ childs: [UserEntity])
    func dismissChildCreateCompletion()
//    func displayEmail(_ email: String)
//    func displayName(_ name: String)
//    func displayPassword(_ password: String)
}

protocol ProfileViewModel: ObservableObject {
    var isLoading: Bool { get set }
    var isUserCreationActive: Bool { get set }
    var user: UserEntity { get }
    var childs: [UserEntity] { get }
//    var title: String { get }
//    var email: String { get }
//    var name: String { get }
//    var password: String { get }
//    var isDisabled: Bool { get }
}

final class DefaultProfileViewModel: ProfileViewModel {
    @Published var isLoading = false
    @Published var isUserCreationActive = false
    @Published private(set) var user: UserEntity = .init(id: "", email: "", name: "", role: .unknown)
    @Published private(set) var childs: [UserEntity] = .init()
//    @Published private(set) var title: String = "Naujos tėvų rolės registracijos forma"
//    @Published private(set) var email: String = ""
//    @Published private(set) var name: String = ""
//    @Published private(set) var password: String = ""
//    @Published private(set) var isDisabled: Bool = true
}

// MARK: - Display Logic

extension DefaultProfileViewModel: ProfileDisplayLogic {
    func dismissChildCreateCompletion() {
        isUserCreationActive = false
    }

    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func displayUser(_ user: UserEntity) {
        self.user = user
    }

    func displayChilds(_ childs: [UserEntity]) {
        self.childs = childs
    }

//    func displayEmail(_ email: String) {
//        self.email = email
//        manageDisableState()
//    }
//
//    func displayName(_ name: String) {
//        self.name = name
//        manageDisableState()
//    }
//
//    func displayPassword(_ password: String) {
//        self.password = password
//        manageDisableState()
//    }
//
//    private func manageDisableState() {
//        isDisabled = email.isEmpty || password.isEmpty || name.isEmpty
//    }
}
