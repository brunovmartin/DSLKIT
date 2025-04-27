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

    /// Create a context with optional initial variables.
    public init(initial: [String: Any] = [:]) {
        self.storage = initial
//        print("--- DEBUG: DSLContext INIT - ID: \(id)") // <-- ADICIONE AQUI
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
        if let current = storage[key] as? AnyHashable,
           let newValue = value as? AnyHashable,
           current == newValue {
            return // Não notifica se não mudou
        }

        storage[key] = value
        objectWillChange.send()
    }

    /// Evaluate a raw expression in the context of this DSL.
    /// - Parameter expr: Can be a literal, a binding, or other supported expression type.
    /// - Returns: The result of evaluation.
    public func evaluate(_ expr: Any) -> Any? {
        DSLExpression.shared.evaluate(expr, self)
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
}
