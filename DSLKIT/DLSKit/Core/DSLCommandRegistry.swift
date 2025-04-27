// swift-helloworld-main/HelloWorld/DLSKit/Core/DSLCommandRegistry.swift
import Foundation // Certifique-se que Foundation está importado

public class DSLCommandRegistry {
    public static let shared = DSLCommandRegistry()

    // MUDE A ASSINATURA AQUI para aceitar Any? como payload
    private var registry: [String: (Any?, DSLContext) -> Void] = [:] // <<-- MUDANÇA AQUI

    private init() {}

    // MUDE A ASSINATURA AQUI também
    public func register(_ name: String, _ fn: @escaping (Any?, DSLContext) -> Void) { // <<-- MUDANÇA AQUI
        registry[name] = fn
    }

    public func execute(_ command: [String: Any], context: DSLContext) {
        guard let key = command.keys.first,
              let executor = registry[key] else {
            //print("⚠️ Comando não registrado: \(command.keys.first ?? "unknown")")
            return
        }

        // Pega o valor associado à chave (o payload real) como Any?
        let payloadValue = command[key]

        // Chama o executor passando o payloadValue diretamente como Any?
        //print("--- DEBUG: DSLCommandRegistry - Executing '\(key)' with payload: \(String(describing: payloadValue))") // Debug
        executor(payloadValue, context) // <<-- MUDANÇA AQUI
    }
}
