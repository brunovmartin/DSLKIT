//
//  LogicOperators.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import Foundation

public class LogicOperators {
    public static func registerAll() {

        // Logic.eq → igualdade
        DSLOperatorRegistry.shared.register("Logic.eq") { input, _ in
            guard let list = input as? [Any], list.count == 2 else { return false }
            return areEqual(list[0], list[1])
        }

        // Logic.neq → desigualdade
        DSLOperatorRegistry.shared.register("Logic.neq") { input, _ in
            guard let list = input as? [Any], list.count == 2 else { return true }
            return !areEqual(list[0], list[1])
        }

        // Logic.and → todas as condições verdadeiras
        DSLOperatorRegistry.shared.register("Logic.and") { input, _ in
            guard let list = input as? [Any] else { return false }
            return list.allSatisfy { ($0 as? Bool) == true }
        }

        // Logic.or → alguma condição verdadeira
        DSLOperatorRegistry.shared.register("Logic.or") { input, _ in
            guard let list = input as? [Any] else { return false }
            return list.contains { ($0 as? Bool) == true }
        }

        // Logic.not → inverte o booleano
        DSLOperatorRegistry.shared.register("Logic.not") { input, _ in
            guard let bool = input as? Bool else { return false }
            return !bool
        }
    }
    
    private static func areEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        // Primeiro, normalizamos os valores para lidar com NSNull e nil
        let normalizedLhs = lhs is NSNull ? nil : lhs
        let normalizedRhs = rhs is NSNull ? nil : rhs
        
        switch (normalizedLhs, normalizedRhs) {
        case (nil, nil):
            return true
        case (let l as String, let r as String):
            return l == r
        case (let l as NSNumber, let r as NSNumber):
            return l == r
        case (let l as Int, let r as Int):
            return l == r
        case (let l as Double, let r as Double):
            return l == r
        case (let l as Bool, let r as Bool):
            return l == r
        case (let l as [String: Any], let r as [String: Any]):
            return NSDictionary(dictionary: l).isEqual(to: r)
        case (let l as [Any], let r as [Any]):
            guard l.count == r.count else { return false }
            for (index, element) in l.enumerated() {
                if !areEqual(element, r[index]) {
                    return false
                }
            }
            return true
        case (let swiftArray as [Any], let nsArray as NSArray):
            return swiftArray.isEmpty && nsArray.count == 0
        case (let nsArray as NSArray, let swiftArray as [Any]):
            return swiftArray.isEmpty && nsArray.count == 0
        default:
            print("⚠️ areEqual: Comparing unhandled types \(type(of: normalizedLhs)) and \(type(of: normalizedRhs)). Returning false.")
            return false
        }
    } 
}
