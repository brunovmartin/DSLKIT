//
//  NumberOperators.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


// Em NumberOperators.swift (ou MathOperators.swift)
import Foundation

public class NumberOperators { // Ou MathOperators
    public static func registerAll() {

        // Operador para formatar número como Int se for inteiro, senão como Double
        DSLOperatorRegistry.shared.register("Number.toIntString") { input, context in
            // O input pode ser o valor diretamente ou uma expressão a avaliar
            // Ex JSON: {"Number.toIntString": 12.0} ou {"Number.toIntString": {"var": "sumResult"}}
            let evaluatedValue = DSLExpression.shared.evaluate(input, context)

            guard let number = evaluatedValue as? NSNumber else {
                 // Se não for número, retorna como string normal ou vazio
                 //logDebug("⚠️ Number.toIntString - Input não é um número: \(String(describing: evaluatedValue))")
                 return (evaluatedValue != nil) ? "\(evaluatedValue!)" : ""
            }

            let doubleValue = number.doubleValue
            // Verifica se é um número inteiro
            if doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                //logDebug("--- DEBUG: Number.toIntString - Formatting as Int: \(Int(doubleValue))")
                return String(Int(doubleValue)) // Formata como Int
            } else {
                //logDebug("--- DEBUG: Number.toIntString - Formatting as Double: \(doubleValue)")
                return String(doubleValue) // Formata como Double (com decimal)
            }
        }

        // Adicione outros operadores de formatação aqui se necessário no futuro
        // ex: Number.formatDecimal(value, places: 2)

    }
}
