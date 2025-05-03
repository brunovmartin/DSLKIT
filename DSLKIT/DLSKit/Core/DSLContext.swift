//
//  DSLContext.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import Foundation

/// DSLContext holds dynamic values and notifies SwiftUI views when they change.
public class DSLContext: ObservableObject {
    let id = UUID()
    /// Storage for variables used in the DSL.
    @Published public private(set) var storage: [String: Any]
    @Published var isInitialLoadComplete = false
    
    // Propriedade para o índice atual (usado em listas/loops)
    public internal(set) var currentIndex: Int? = nil // nil por padrão
    
    // Adiciona um mecanismo para rastrear atualizações pendentes
    private var pendingUpdates: Set<String> = []
    /// Create a context with optional initial variables.
    public init(initial: [String: Any] = [:]) {
        self.storage = initial
//        logDebug("--- DEBUG: DSLContext INIT - ID: \(id)") // <-- ADICIONE AQUI
    }

    /// Retrieve the value for a given key.
    /// - Parameter key: The name of the variable.
    /// - Returns: The value if present, or nil.
    public func get(_ key: String) -> Any? {
        storage[key]
    }

    /// Set or update the value for a given key and notify observers.
    /// - Parameters:
    ///   - key: The name of the variable.
    ///   - value: The new value to assign.
    public func set(_ key: String, to value: Any) {
        // Tenta comparar como AnyHashable para evitar notificações desnecessárias
        if let current = storage[key] as? AnyHashable,
           let newValue = value as? AnyHashable,
           current == newValue {
            logDebug("--- DEBUG: DSLContext SET - Value for \(key) unchanged. Skipping update.")
            return // Não notifica se não mudou
        }
        
        logDebug("--- DEBUG: DSLContext SET - Triggering objectWillChange for \(key)")
        // Chama objectWillChange manualmente ANTES da mudança
        objectWillChange.send()
        
        logDebug("--- DEBUG: DSLContext SET - Updating \(key) to: \(value)")
        storage[key] = value 
        // @Published cuida da notificação APÓS a mudança
    }


    /// Subscript to get or set context values directly.
    public subscript(key: String) -> Any? {
        get { storage[key] }
        set {
            if let v = newValue {
                storage[key] = v
            } else {
                storage.removeValue(forKey: key)
            }
        }
    }
    
    func startUpdate(for key: String) {
        pendingUpdates.insert(key)
    }
    
    func completeUpdate(for key: String) {
        pendingUpdates.remove(key)
    }
    
    var hasPendingUpdates: Bool {
        !pendingUpdates.isEmpty
    }
    
    // Método para observar quando todas as atualizações estiverem completas
    func waitForUpdates(completion: @escaping () -> Void) {
        // Primeiro resolve todas as expressões pendentes
        resolveAllExpressions()
        
        // Depois verifica se ainda há atualizações pendentes
        if !hasPendingUpdates {
            completion()
            return
        }
        
        var timer: Timer?
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else {
                timer?.invalidate()
                return
            }
            
            // Tenta resolver expressões novamente
            self.resolveAllExpressions()
            
            if !self.hasPendingUpdates {
                timer?.invalidate()
                completion()
            }
        }
    }
    
    func set(key: String, value: Any?) {
        startUpdate(for: key) // Marca o início da atualização
        
        // Executa a atualização original
        storage[key] = value
        objectWillChange.send()
        
        // Marca a atualização como completa
        completeUpdate(for: key)
    }
    
    func resolveAllExpressions() {
        var hasChanges = true
        var iterationCount = 0
        let maxIterations = 10 // Prevenir loops infinitos
        
        while hasChanges && iterationCount < maxIterations {
            hasChanges = false
            iterationCount += 1
            
            for (key, value) in storage {
                if let expression = value as? [String: Any] {
                    let resolvedValue = DSLExpression.shared.evaluate(expression, self)
                    if !areEqual(value, resolvedValue) {
                        set(key: key, value: resolvedValue)
                        hasChanges = true
                    }
                }
            }
        }
        
        if iterationCount >= maxIterations {
            logDebug("⚠️ WARNING: Maximum iterations reached while resolving expressions")
        }
    }
    
    private func areEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (let l as String, let r as String):
            return l == r
        case (let l as [String: Any], let r as [String: Any]):
            return NSDictionary(dictionary: l).isEqual(to: r)
        case (let l as [Any], let r as [Any]):
            guard l.count == r.count else { return false }
            for (index, element) in l.enumerated() {
                if !areEqual(element, r[index]) {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }

    // Adicione um método auxiliar para criar um contexto filho com um índice
    // Isso evita modificar diretamente o estado do contexto pai durante a iteração
    func contextForIndex(_ index: Int) -> DSLContext {
        // Cria um novo contexto que compartilha o storage principal, mas tem seu próprio currentIndex
        // NOTA: Isso assume que o storage é o estado compartilhado principal. Se houver outras
        // propriedades que precisam ser específicas do índice, ajuste esta lógica.
        let childContext = DSLContext(initial: self.storage) // Reutiliza o storage
        childContext.currentIndex = index
        childContext.isInitialLoadComplete = self.isInitialLoadComplete // Herda o estado de carregamento
        // Você pode precisar copiar/referenciar outros estados relevantes do contexto pai aqui
        return childContext
    }
}
