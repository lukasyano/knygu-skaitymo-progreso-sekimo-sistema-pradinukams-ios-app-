import SwiftUI

protocol Coordinator: ObservableObject {
    associatedtype PresentedView: Identifiable
    associatedtype Route

    var parent: (any Coordinator)? { get }
    var presentedView: PresentedView? { get set }
    var route: Route? { get set }

//    func startNoInternet(_ action: (() -> Void)?)
//    func startNoInternet()

    func dismissPresented()
    func popToStart()
    @discardableResult func popToParent() -> (any Coordinator)?
    func popToRoot()
    func popToCoordinator<C: Coordinator>(_ coordinatorType: C.Type)
}

extension Coordinator {
    // MARK: - Navigation

//    func startGenericError(_ config: GenericErrorConfig, action: @escaping () -> Void) {
//        self.message = .genericError(config, action: action)
//    }

//    func startNoInternet(_ action: (() -> Void)? = nil) {
//        message = .noInternet(action: action)
//    }

//    func startNoInternet() {
//        startNoInternet(nil)
//    }

    // MARK: - Dismissal

    func dismissPresented() {
        presentedView = nil
    }

    func popToStart() {
        presentedView = nil
        route = nil
    }

    @discardableResult func popToParent() -> (any Coordinator)? {
        popToStart()
        parent?.popToStart()
        return parent
    }

    func popToRoot() {
        var parent = popToParent()
        while parent != nil {
            parent = parent?.popToParent()
        }
    }

    func popToCoordinator<C: Coordinator>(_ coordinatorType: C.Type) {
        guard isCoordinatorInStack(coordinatorType) else {
            return
        }

        var parent = popToParent()
        while parent != nil {
            if parent is C {
                return
            } else {
                parent = parent?.popToParent()
            }
        }
    }

    private func isCoordinatorInStack<C: Coordinator>(_: C.Type) -> Bool {
        var parent = parent
        while parent != nil {
            if parent is C {
                return true
            } else {
                parent = parent?.parent
            }
        }
        return false
    }
}
