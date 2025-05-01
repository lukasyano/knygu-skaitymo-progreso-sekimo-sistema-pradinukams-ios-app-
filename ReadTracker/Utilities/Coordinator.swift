import SwiftUI

protocol Coordinator: ObservableObject {
    associatedtype PresentedView: Identifiable
    associatedtype Route

    var parent: (any Coordinator)? { get }
    var presentedView: PresentedView? { get set }
    var route: Route? { get set }

    func dismissPresented()
    func popToStart()
    @discardableResult func popToParent() -> (any Coordinator)?
    func popToRoot()
    func popToCoordinator<C: Coordinator>(_ coordinatorType: C.Type)
}

extension Coordinator {

    // MARK: - Dismissal
    func dismissPresented() {
        presentedView = nil
    }

    func popToStart() {
        presentedView = nil
        route = nil
    }

    @discardableResult func popToParent() -> (any Coordinator)? {
        print("  popToParent() on \(Self.self)")
        popToStart()
        parent?.popToStart()
        return parent
    }

    func popToRoot() {
        print("popToRoot() on \(Self.self)")
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
