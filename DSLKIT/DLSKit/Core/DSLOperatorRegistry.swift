//
//  DSLOperatorRegistry.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import Foundation

public class DSLOperatorRegistry {
    public static let shared = DSLOperatorRegistry()

    private var registry: [String: (Any?, DSLContext) -> Any?] = [:]

    private init() {}

    /// Registra um operador como "String.trim", "Logic.eq"
    public func register(_ name: String, _ fn: @escaping (Any?, DSLContext) -> Any?) {
        registry[name] = fn
    }

    /// Executa o operador declarado no JSON
    public func evaluate(_ name: String, input: Any?, context: DSLContext) -> Any? {
        guard let op = registry[name] else {
            print("⚠️ Operador não registrado: \(name)")
            return nil
        }
        return op(input, context)
    }
    
    public func isRegistered(_ name: String) -> Bool {
        return registry[name] != nil
    }

    // MARK: - Storage Operators
    public func registerDefaults() {
        StringOperators.registerAll()
        ArrayOperators.registerAll()
        LogicOperators.registerAll()
        MathOperators.registerAll()
        NumberOperators.registerAll()
        ConditionalOperators.registerAll()
        StorageOperators.registerAll()
    }
}
