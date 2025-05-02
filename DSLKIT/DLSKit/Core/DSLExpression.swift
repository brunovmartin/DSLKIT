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
             var evaluatedDict: [String: Any] = [:] // Must be [String: Any]
             for (key, value) in dict {
                 // Evaluate recursively. If result is not nil, add to dict.
                 if let evaluatedValue = evaluate(value, context) { 
                     evaluatedDict[key] = evaluatedValue
                 } // Implicitly skip if evaluate returns nil
             }
             print("--- DEBUG: DSLExpression - Evaluated Dictionary Literal: \(evaluatedDict)")
             return evaluatedDict
        }

        // Caso 3: Array Literal
        if let array = expr as? [Any] {
             print("--- DEBUG: DSLExpression - Evaluating Array Literal items...")
             // Use compactMap to evaluate items and filter out nil results.
             // The result is [Any], not [Any?].
             let evaluatedArray = array.compactMap { evaluate($0, context) } 
             print("--- DEBUG: DSLExpression - Evaluated Array Literal: \(evaluatedArray)")
             return evaluatedArray
        }

        // Caso 4: Outros Literais Primitivos
        // Retorna o próprio literal, que já é Any (não Any?)
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
            guard currentNonNullValue != nil else { return nil }

            // --- Refactored Logic --- 
            switch component {
            case let index as Int:
                // Direct integer index access
                guard let array = currentNonNullValue as? [Any] else { 
                    print("⚠️ Path Resolution: Trying to access index \(index) on non-array: \(currentNonNullValue!)")
                    return nil 
                }
                guard index >= 0 && index < array.count else { 
                    print("⚠️ Path Resolution: Index \(index) out of bounds for array of count \(array.count).")
                    return nil 
                }
                currentValue = array[index]

            case let key as String:
                // String key access (literal or variable)
                if key.hasPrefix("VAR::") {
                    // --- Variable Key/Index --- 
                    let variableName = String(key.dropFirst(5))
                    guard let resolvedVariable = evaluate(["var": variableName], context) else {
                        print("⚠️ Path Resolution: Variable '\(variableName)' not found in context.")
                        return nil
                    }
                    
                    // Check type of current value to determine access method
                    if let dict = currentNonNullValue as? [String: Any] {
                        // Access Dictionary with resolved variable (must resolve to String key)
                        guard let resolvedKey = resolvedVariable as? String else {
                            print("⚠️ Path Resolution: Variable '\(variableName)' did not resolve to a String key for dictionary access.")
                            return nil
                        }
                        print("--- DEBUG: Path Resolution - Using dynamic key: \(resolvedKey)")
                        currentValue = dict[resolvedKey]
                    } else if let array = currentNonNullValue as? [Any] {
                        // Access Array with resolved variable (must resolve to Int index)
                        guard let resolvedIndex = resolvedVariable as? Int else {
                            print("⚠️ Path Resolution: Variable '\(variableName)' did not resolve to an Int index for array access.")
                            return nil
                        }
                         print("--- DEBUG: Path Resolution - Using dynamic index: \(resolvedIndex)")
                        guard resolvedIndex >= 0 && resolvedIndex < array.count else { 
                            print("⚠️ Path Resolution: Resolved index \(resolvedIndex) out of bounds for array of count \(array.count).")
                            return nil 
                        }
                        currentValue = array[resolvedIndex]
                    } else {
                        print("⚠️ Path Resolution: Cannot use variable '\(variableName)' to access non-dictionary/non-array: \(currentNonNullValue!)")
                        return nil
                    }
                    // --- End Variable Key/Index ---
                } else {
                    // --- Literal String Key --- 
                    guard let dict = currentNonNullValue as? [String: Any] else { 
                        print("⚠️ Path Resolution: Trying to access literal key '\(key)' on non-dictionary: \(currentNonNullValue!)")
                        return nil 
                    }
                    currentValue = dict[key]
                    // --- End Literal String Key ---
                }
                
            default:
                 // Invalid component type
                 print("⚠️ Path Resolution: Invalid component type: \(component)")
                 return nil
            }
             // --- End Refactored Logic ---
        }

        // Return unwrapped value or nil (already corrected)
        if let finalValue = currentValue, !(finalValue is NSNull) {
            return finalValue 
        } else {
            return nil
        }
    }
}
