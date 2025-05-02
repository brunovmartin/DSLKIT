// swift-helloworld-main/HelloWorld/DLSKit/Core/DSLExpression.swift
import Foundation

public class DSLExpression {
    public static let shared = DSLExpression()

    // Função principal de avaliação (sem localOverrides)
    // Reverte a função para síncrona
    public func evaluate(_ expr: Any?, _ context: DSLContext) -> Any? {
        guard let expr = expr else { return nil }

        // Caso 0: Variáveis com Path (ex: {"var": "items[0].title"})
        if let dict = expr as? [String: Any],
           dict.keys.count == 1,
           let pathString = dict["var"] as? String {
            print("--- DEBUG: DSLExpression - Evaluating path: \(pathString)")
            // resolvePath é síncrono
            return resolvePath(pathString, context: context) // Chama helper de leitura
        }

        // Caso 1: Operadores
        if let dict = expr as? [String: Any],
           let opName = dict.keys.first,
           let input = dict[opName],
           DSLOperatorRegistry.shared.isRegistered(opName) {
             print("--- DEBUG: DSLExpression - Evaluating REGISTERED operator: \(opName)")
             var evaluatedInput: Any?
            if let inputArray = input as? [Any] {
                // Avalia itens do array de forma síncrona
                evaluatedInput = inputArray.map { item in
                    evaluate(item, context) // Avaliação recursiva SEM overrides
                }
            } else {
                evaluatedInput = evaluate(input, context) // Avaliação recursiva SEM overrides
            }
             print("--- DEBUG: DSLExpression - Operator evaluated input: \(String(describing: evaluatedInput))")
             // Chamada síncrona para o operador
             return DSLOperatorRegistry.shared.evaluate(opName, input: evaluatedInput, context: context)
        }

        // Caso 2: Dicionário Literal
        if let dict = expr as? [String: Any] {
             print("--- DEBUG: DSLExpression - Evaluating Dictionary Literal Values: \(dict)")
             // Avalia valores do dicionário de forma síncrona
             var evaluatedDict: [String: Any] = [:]
             for (key, value) in dict {
                 evaluatedDict[key] = evaluate(value, context) // Avaliação recursiva SEM overrides
             }
             print("--- DEBUG: DSLExpression - Evaluated Dictionary Literal: \(evaluatedDict)")
             return evaluatedDict
        }

        // Caso 3: Array Literal
        if let array = expr as? [Any] {
             print("--- DEBUG: DSLExpression - Evaluating Array Literal items...")
             // Avalia itens do array de forma síncrona
             let evaluatedArray = array.map { evaluate($0, context) } // Avaliação recursiva SEM overrides
             print("--- DEBUG: DSLExpression - Evaluated Array Literal: \(evaluatedArray)")
             return evaluatedArray
        }

        // Caso 4: Outros Literais Primitivos
        ////print("--- DEBUG: DSLExpression - Returning literal primitive: \(expr)")
        return expr
    }

    // --- Função resolvePath para LEITURA ---
    private func resolvePath(_ path: String, context: DSLContext) -> Any? {
        let components = VariableCommands.parsePathComponents(path, context: context)
        guard !components.isEmpty, let baseVar = components[0] as? String else {
            return nil
        }

        var currentValue: Any? = context.get(baseVar)

        for component in components.dropFirst() {
            let currentNonNullValue = (currentValue is NSNull) ? nil : currentValue
            guard currentNonNullValue != nil else {
                return nil
            }

            if let index = component as? Int { // Acesso a Array por Índice Numérico
                guard let array = currentNonNullValue as? [Any] else { return nil }
                guard index >= 0 && index < array.count else { return nil }
                currentValue = array[index]
            } 
            else if let key = component as? String {
                // Verifica se é uma chave dinâmica
                if key.hasPrefix("VAR::") {
                    let variableName = String(key.dropFirst(5)) // Remove "VAR::"
                    // Avalia a variável para obter a chave real (ex: "light" ou "dark")
                    guard let resolvedKey = evaluate(["var": variableName], context) as? String else {
                         print("⚠️ Path Resolution: Dynamic key variable '\(variableName)' not found or not a String.")
                         return nil
                    }
                    // Usa a chave resolvida para acessar o dicionário
                    guard let dict = currentNonNullValue as? [String: Any] else {
                        print("⚠️ Path Resolution: Trying to access dynamic key '\(resolvedKey)' on non-dictionary: \(currentNonNullValue!)")
                        return nil
                    }
                    print("--- DEBUG: Path Resolution - Using dynamic key: \(resolvedKey)")
                    currentValue = dict[resolvedKey]
                } else { 
                    // Chave literal normal
                    guard let dict = currentNonNullValue as? [String: Any] else { return nil }
                    currentValue = dict[key]
                }
            }
            else { 
                return nil // Componente inválido
            }
        }
        return (currentValue is NSNull) ? nil : currentValue
    }
}
