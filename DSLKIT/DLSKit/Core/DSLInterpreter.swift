import SwiftUI
import Combine

public class DSLInterpreter: ObservableObject {
    public static let shared = DSLInterpreter()

    @Published public var currentView: AnyView?
    // currentTitle is removed

    private var currentContext: DSLContext?
    private var screenStack: [[String: Any]] = []

    init() {
         //print("--- DEBUG: DSLInterpreter INIT ---")
    }

    // updateTitle is removed

    public func present(screen: [String: Any], context: DSLContext) {
        //print("--- DEBUG: DSLInterpreter.present - Using received context ID: \(context.id)")
        self.currentContext = context
        screenStack = [screen] // Reset stack
        // Render the initial view. Title calculation happens inside render.
        let newView = AnyView(DSLViewRenderer.render(screen: screen, context: context))
        self.currentView = newView
        //print("--- DEBUG: DSLInterpreter.present - self.currentView SET")
    }

    public func push(screen: [String: Any]) {
         guard let context = self.currentContext else { return }
         screenStack.append(screen)
         // Render the pushed view. Title calculation happens inside render.
         let newView = AnyView(DSLViewRenderer.render(screen: screen, context: context))
         self.currentView = newView
         //print("--- DEBUG: DSLInterpreter.push - self.currentView SET")
    }

    public func pop() {
        guard screenStack.count > 1, let context = self.currentContext else { return }
        _ = screenStack.popLast()
        if let previous = screenStack.last {
             // Render the popped-to view. Title calculation happens inside render.
             let newView = AnyView(DSLViewRenderer.render(screen: previous, context: context))
             self.currentView = newView
             //print("--- DEBUG: DSLInterpreter.pop - self.currentView SET")
        }
    }

    public func handleEvent(_ action: Any, context: DSLContext) {
        if let command = action as? [String: Any] {
            DSLCommandRegistry.shared.execute(command, context: context)
        } else if let sequence = action as? [[String: Any]] {
            for cmd in sequence {
                DSLCommandRegistry.shared.execute(cmd, context: context)
            }
        }
        if let screen = screenStack.last, let ctx = self.currentContext {
             DispatchQueue.main.async {
                 let updatedView = AnyView(DSLViewRenderer.render(screen: screen, context: ctx))
                 self.currentView = updatedView
             }
        }
    }
}
