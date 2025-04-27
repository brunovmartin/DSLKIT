//
//  ArrayOperators.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import Foundation

public class ArrayOperators {
    public static func registerAll() {

        // Array.indexOf → retorna o índice de um item ou -1
        DSLOperatorRegistry.shared.register("Array.indexOf") { input, _ in
            guard let dict = input as? [String: Any],
                  let array = dict["source"] as? [Any],
                  let target = dict["search"] else {
                return nil
            }

            for (i, element) in array.enumerated() {
                if "\(element)" == "\(target)" {
                    return i
                }
            }
            return -1
        }

        // Array.contains → retorna true se o item existir
        DSLOperatorRegistry.shared.register("Array.contains") { input, _ in
            guard let dict = input as? [String: Any],
                  let array = dict["source"] as? [Any],
                  let target = dict["search"] else {
                return nil
            }

            return array.contains { "\($0)" == "\(target)" }
        }
    }
}
