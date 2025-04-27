import SwiftUI
import Combine

public class DSLInterpreter: ObservableObject {
    public static let shared = DSLInterpreter()

    @Published public var navigationPath: [String] = [] // Pilha de IDs de tela

    private var currentContext: DSLContext?
    private var rootScreenId: String? // Para saber qual é a tela raiz

    private init() {
         //print("--- DEBUG: DSLInterpreter INIT ---")
    }

    public func present(screen: [String: Any], context: DSLContext) {
        self.currentContext = context
        self.rootScreenId = screen["id"] as? String // Guarda o ID da raiz
        self.navigationPath = [] // Limpa a pilha de navegação
        // Não renderizamos mais a view aqui, App.swift fará isso
        print("--- DEBUG: Interpreter.present - Root screen set to: \(rootScreenId ?? "nil"). Path cleared.")
    }
    
    public func pushScreen(withId screenId: String) {
         // Verifica se a tela existe antes de empilhar (opcional, mas bom)
        guard DSLAppEngine.shared.getScreenDefinition(byId: screenId) != nil else {
             print("⚠️ Interpreter.pushScreen - Tentativa de empilhar tela não existente: \(screenId)")
             return
        }
        navigationPath.append(screenId)
        print("--- DEBUG: Interpreter.pushScreen - Appended '\(screenId)' to path. New path: \(navigationPath)")
    }

    public func popScreen() {
        if !navigationPath.isEmpty {
            let removed = navigationPath.removeLast()
            print("--- DEBUG: Interpreter.popScreen - Removed '\(removed)' from path. New path: \(navigationPath)")
        } else {
             print("--- DEBUG: Interpreter.popScreen - Path is empty, cannot pop.")
        }
    }
    
    public func handleEvent(_ eventData: Any, context: DSLContext) {
        print("--- DEBUG: Interpreter handleEvent - Received event data: \(String(describing: eventData))")
        // Garantir que o contexto usado é o atual
        guard self.currentContext === context else {
             print("⚠️ Interpreter handleEvent - Context mismatch.")
             // Considerar a melhor estratégia aqui: parar, continuar, atualizar contexto?
             // Por segurança, vamos parar por enquanto.
             return 
        }

        if let command = eventData as? [String: Any] {
            DSLCommandRegistry.shared.execute(command, context: context)
        } else if let sequence = eventData as? [[String: Any]] {
            for cmd in sequence {
                DSLCommandRegistry.shared.execute(cmd, context: context)
            }
        }
        // NÃO precisamos mais forçar re-render aqui, @Published fará o trabalho
        print("--- DEBUG: Interpreter handleEvent - Finished processing event.")
    }
    
    func getRootScreenDefinition() -> [String: Any]? {
         guard let id = rootScreenId else { return nil }
         return DSLAppEngine.shared.getScreenDefinition(byId: id)
     }
}
