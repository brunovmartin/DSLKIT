// swift-helloworld-main/HelloWorld/DLSKit/Core/DSLExpression.swift
import Foundation

public class DSLExpression {
    public static let shared = DSLExpression()

    // Função principal de avaliação
    public func evaluate(_ expr: Any?, _ context: DSLContext) -> Any? {
        // 1. Resolver placeholders ANTES de avaliar o resto
        let resolvedExpr = resolvePlaceholdersRecursively(expr, context: context)

        guard let currentExpr = resolvedExpr else { return nil }

        // Caso 0: Variáveis com Path (ex: {"var": "items[0].title"})
        if let dict = currentExpr as? [String: Any],
           dict.keys.count == 1,
           let pathString = dict["var"] as? String {
            print("--- DEBUG: DSLExpression - Evaluating path: \(pathString)")
            return resolvePath(pathString, context: context) // Passa o contexto original
        }

        // Caso 1: Operadores
        if let dict = currentExpr as? [String: Any],
           let opName = dict.keys.first,
           let input = dict[opName],
           DSLOperatorRegistry.shared.isRegistered(opName) {
             print("--- DEBUG: DSLExpression - Evaluating REGISTERED operator: \(opName)")
             var evaluatedInput: Any?
            if let inputArray = input as? [Any] {
                evaluatedInput = inputArray.map { item in
                    // Avaliação recursiva usa o MESMO contexto (que já tem o índice, se aplicável)
                    evaluate(item, context)
                }
            } else {
                evaluatedInput = evaluate(input, context)
            }
             print("--- DEBUG: DSLExpression - Operator evaluated input: \(String(describing: evaluatedInput))")
             return DSLOperatorRegistry.shared.evaluate(opName, input: evaluatedInput, context: context)
        }

        // Caso 2: Dicionário Literal
        if let dict = currentExpr as? [String: Any] {
             print("--- DEBUG: DSLExpression - Evaluating Dictionary Literal Values: \(dict)")
             var evaluatedDict: [String: Any] = [:]
             for (key, value) in dict {
                 // Avalia valores recursivamente usando o mesmo contexto
                 if let evaluatedValue = evaluate(value, context) { 
                     evaluatedDict[key] = evaluatedValue
                 }
             }
             print("--- DEBUG: DSLExpression - Evaluated Dictionary Literal: \(evaluatedDict)")
             return evaluatedDict
        }

        // Caso 3: Array Literal
        if let array = currentExpr as? [Any] {
             print("--- DEBUG: DSLExpression - Evaluating Array Literal items...")
             // Avalia itens recursivamente usando o mesmo contexto
             let evaluatedArray = array.compactMap { evaluate($0, context) } 
             print("--- DEBUG: DSLExpression - Evaluated Array Literal: \(evaluatedArray)")
             return evaluatedArray
        }

        // Caso 4: Outros Literais Primitivos
        return currentExpr // Retorna a expressão (possivelmente modificada pelos placeholders)
    }

    // --- Nova função de resolução de placeholders ---
    private func resolvePlaceholdersRecursively(_ data: Any?, context: DSLContext) -> Any? {
        guard let data = data else { return nil }
        guard let index = context.currentIndex else {
            // Se não há currentIndex no contexto, não há nada para substituir.
            // Retorna os dados originais.
            return data
        }

        // Placeholder atual que estamos procurando
        let indexPlaceholder = "[currentItemIndex]" // Poderia vir de uma config futuramente

        if var dict = data as? [String: Any] {
            var newDict = [String: Any]()
            var dictionaryModified = false // Flag para checar se houve modificação direta no 'var'

            // Verifica se a chave 'var' existe e contém o placeholder
            if let path = dict["var"] as? String, path.contains(indexPlaceholder) {
                let actualPath = path.replacingOccurrences(of: indexPlaceholder, with: "[\(index)]")
                newDict["var"] = actualPath // Atualiza no novo dicionário
                dictionaryModified = true
                // Copia as outras chaves, se houver (embora o padrão comum seja só ter 'var')
                for (key, value) in dict where key != "var" {
                    // Resolve placeholders recursivamente nos outros valores também
                    newDict[key] = resolvePlaceholdersRecursively(value, context: context)
                }
            } else {
                // Se não achou 'var' com placeholder, processa todos os valores recursivamente
                for (key, value) in dict {
                    newDict[key] = resolvePlaceholdersRecursively(value, context: context)
                }
            }
           //print("--- Substitute (\(index)): Processed dict: \(newDict)")
            return newDict

        } else if let array = data as? [Any] {
            // Processa cada elemento do array recursivamente
            let newArray = array.map { resolvePlaceholdersRecursively($0, context: context) }
           //print("--- Substitute (\(index)): Processed array: \(newArray)")
            return newArray

        } else if let stringValue = data as? String, stringValue.contains(indexPlaceholder) {
             // CASO EXTRA: Se a própria string contiver o placeholder (fora de um {"var": ...})
             // Isso pode ou não ser desejado, dependendo da sua DSL.
             // Exemplo: "text": "Item [currentItemIndex]"
             let resolvedString = stringValue.replacingOccurrences(of: indexPlaceholder, with: "\(index)")
             //print("--- Substitute (\(index)): Resolved placeholder in String: \(resolvedString)")
             return resolvedString
        }
        else {
            // É um valor literal (Int, Double, Bool, ou String sem placeholder), retorna como está
            //print("--- Substitute (\(index)): Returning literal: \(data)")
            return data
        }
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
