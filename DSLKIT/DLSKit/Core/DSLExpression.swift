// swift-helloworld-main/HelloWorld/DLSKit/Core/DSLExpression.swift
import Foundation

public class DSLExpression {
    public static let shared = DSLExpression()

    // Função principal de avaliação (sem localOverrides)
    public func evaluate(_ expr: Any?, _ context: DSLContext) -> Any? {
        guard let expr = expr else { return nil }

        // Caso 0: Variáveis com Path (ex: {"var": "items[0].title"})
        if let dict = expr as? [String: Any],
           dict.keys.count == 1,
           let pathString = dict["var"] as? String {
            //print("--- DEBUG: DSLExpression - Evaluating path: \(pathString)")
            return resolvePath(pathString, context: context) // Chama helper de leitura
        }

        // Caso 1: Operadores
        if let dict = expr as? [String: Any],
           let opName = dict.keys.first,
           let input = dict[opName],
           DSLOperatorRegistry.shared.isRegistered(opName) {
             //print("--- DEBUG: DSLExpression - Evaluating REGISTERED operator: \(opName)")
             var evaluatedInput: Any?
            if var inputArray = input as? [Any] {
                evaluatedInput = inputArray.map { item in
                    evaluate(item, context) // Avaliação recursiva SEM overrides
                }
            } else {
                evaluatedInput = evaluate(input, context) // Avaliação recursiva SEM overrides
            }
             //print("--- DEBUG: DSLExpression - Operator evaluated input: \(String(describing: evaluatedInput))")
             // Retorna nil se o operador falhar
             return DSLOperatorRegistry.shared.evaluate(opName, input: evaluatedInput, context: context)
        }

        // Caso 2: Dicionário Literal
        if let dict = expr as? [String: Any] {
             ////print("--- DEBUG: DSLExpression - Evaluating Dictionary Literal Values: \(dict)")
             var evaluatedDict: [String: Any] = [:]
             for (key, value) in dict {
                 evaluatedDict[key] = evaluate(value, context) // Avaliação recursiva SEM overrides
             }
             ////print("--- DEBUG: DSLExpression - Evaluated Dictionary Literal: \(evaluatedDict)")
             return evaluatedDict
        }

        // Caso 3: Array Literal
        if let array = expr as? [Any] {
             ////print("--- DEBUG: DSLExpression - Evaluating Array Literal items...")
             let evaluatedArray = array.map { evaluate($0, context) } // Avaliação recursiva SEM overrides
             ////print("--- DEBUG: DSLExpression - Evaluated Array Literal: \(evaluatedArray)")
             return evaluatedArray
        }

        // Caso 4: Outros Literais Primitivos
        ////print("--- DEBUG: DSLExpression - Returning literal primitive: \(expr)")
        return expr
    }

    // --- Função resolvePath para LEITURA ---
    private func resolvePath(_ path: String, context: DSLContext) -> Any? {
        // Usa a função de parse (pode ser a mesma do VariableCommands)
        let components = VariableCommands.parsePathComponents(path, context: context)
        guard !components.isEmpty, let baseVar = components[0] as? String else {
            ////print("⚠️ Path Read Error: Invalid path or base variable. Path: '\(path)'")
            return nil
        }

        var currentValue: Any? = context.get(baseVar)
//        ////print("--- DEBUG: Path Reader - Base var '\(baseVar)', Initial value: \(String(describing: currentValue))")

        for component in components.dropFirst() {
            let currentNonNullValue = (currentValue is NSNull) ? nil : currentValue
            guard currentNonNullValue != nil else {
//                ////print("⚠️ Path Read Error: Cannot resolve further, current value is nil/NSNull. Path component: \(component)")
                return nil
            }

            if let index = component as? Int { // Acesso a Array
                guard let array = currentNonNullValue as? [Any] else {
//                    //print("⚠️ Path Read Error: Trying to access index '\(index)' on non-array: \(currentNonNullValue!)")
                    return nil
                }
                guard index >= 0 && index < array.count else {
//                    //print("⚠️ Path Read Error: Index \(index) out of bounds for array count \(array.count).")
                    return nil
                }
                currentValue = array[index]
//                //print("--- DEBUG: Path Reader - Accessed index \(index), New value: \(String(describing: currentValue))")
            }
            else if let key = component as? String { // Acesso a Dicionário
                 guard let dict = currentNonNullValue as? [String: Any] else {
//                    //print("⚠️ Path Read Error: Trying to access key '\(key)' on non-dictionary: \(currentNonNullValue!)")
                    return nil
                }
                currentValue = dict[key] // Pode ser nil ou NSNull
//                //print("--- DEBUG: Path Reader - Accessed key '\(key)', New value: \(String(describing: currentValue))")
            }
            else { /* Erro: componente inválido */ return nil }
        }
        // Retorna nil em vez de NSNull para simplificar o uso
        return (currentValue is NSNull) ? nil : currentValue
    }
}
