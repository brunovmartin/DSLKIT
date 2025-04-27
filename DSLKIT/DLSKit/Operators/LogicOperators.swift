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
            return "\(list[0])" == "\(list[1])"
        }

        // Logic.neq → desigualdade
        DSLOperatorRegistry.shared.register("Logic.neq") { input, _ in
            guard let list = input as? [Any], list.count == 2 else { return true }
            return "\(list[0])" != "\(list[1])"
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
}
