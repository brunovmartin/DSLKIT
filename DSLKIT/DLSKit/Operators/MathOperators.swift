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
    }
}
