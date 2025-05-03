//
//  MathOperators.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import Foundation

public class MathOperators {
    public static func registerAll() {

        // Math.add
        DSLOperatorRegistry.shared.register("Math.add") { input, _ in
            guard let list = input as? [Any] else { return nil }
            let sum = list.compactMap { ($0 as? NSNumber)?.doubleValue }.reduce(0, +)
            return sum
        }

        // Math.subtract
        DSLOperatorRegistry.shared.register("Math.subtract") { input, _ in
            guard let list = input as? [Any], list.count >= 2 else { return nil }
            let numbers = list.compactMap { ($0 as? NSNumber)?.doubleValue }
            guard let first = numbers.first else { return nil }
            return numbers.dropFirst().reduce(first, -)
        }

        // Math.multiply
        DSLOperatorRegistry.shared.register("Math.multiply") { input, _ in
            guard let list = input as? [Any] else { return nil }
            let product = list.compactMap { ($0 as? NSNumber)?.doubleValue }.reduce(1, *)
            return product
        }

        // Math.divide
        DSLOperatorRegistry.shared.register("Math.divide") { input, _ in
            guard let list = input as? [Any], list.count == 2 else { return nil }
            let nums = list.compactMap { ($0 as? NSNumber)?.doubleValue }
            guard nums.count == 2, nums[1] != 0 else { return nil }
            return nums[0] / nums[1]
        }

        // Math.mod
        DSLOperatorRegistry.shared.register("Math.mod") { input, _ in
            guard let list = input as? [Any], list.count == 2 else { return nil }
            guard let a = (list[0] as? NSNumber)?.intValue,
                  let b = (list[1] as? NSNumber)?.intValue, b != 0 else { return nil }
            return a % b
        }

        // Math.random
        DSLOperatorRegistry.shared.register("Math.random") { input, context in
            // Espera um array [minExpr, maxExpr]
            guard let inputArray = input as? [Any], inputArray.count == 2 else {
                logDebug("⚠️ Math.random: Input inválido. Esperado um array com dois elementos [min, max]. Input: \\(String(describing: input))")
                return nil
            }
            
            // Avalia os limites min e max
            let minExpr = inputArray[0]
            let maxExpr = inputArray[1]
            
            let minValueAny = DSLExpression.shared.evaluate(minExpr, context)
            let maxValueAny = DSLExpression.shared.evaluate(maxExpr, context)
            
            // Tenta converter para Double primeiro (mais geral)
            guard var minDouble = (minValueAny as? NSNumber)?.doubleValue,
                  var maxDouble = (maxValueAny as? NSNumber)?.doubleValue else {
                logDebug("⚠️ Math.random: min ou max não avaliaram para números válidos. Min: \\(String(describing: minValueAny)), Max: \\(String(describing: maxValueAny))")
                return nil
            }
            
            // Garante min <= max
            if minDouble > maxDouble {
                swap(&minDouble, &maxDouble)
                logDebug("ℹ️ Math.random: min era maior que max, valores trocados.")
            }
            
            // Verifica se ambos podem ser representados como Int sem perda
            // (ou se foram originalmente Int)
            let minIsIntRepresentable = floor(minDouble) == minDouble
            let maxIsIntRepresentable = floor(maxDouble) == maxDouble
            let minIsOriginallyInt = minValueAny is Int
            let maxIsOriginallyInt = maxValueAny is Int
            
            // Gera Int se ambos os limites originais eram Int OU
            // se ambos são representáveis como Int sem perda.
            if (minIsOriginallyInt && maxIsOriginallyInt) || (minIsIntRepresentable && maxIsIntRepresentable) {
                let minInt = Int(minDouble)
                let maxInt = Int(maxDouble)
                // Gera Int inclusivo (min...max)
                logDebug("--- DEBUG: Math.random generating Int between \\(minInt) and \\(maxInt)")
                return Int.random(in: minInt...maxInt)
            } else {
                // Gera Double inclusivo (min...max)
                 logDebug("--- DEBUG: Math.random generating Double between \\(minDouble) and \\(maxDouble)")
                return Double.random(in: minDouble...maxDouble)
            }
        }
    }
}
