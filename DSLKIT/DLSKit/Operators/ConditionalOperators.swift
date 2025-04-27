//
//  ConditionalOperators.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 26/04/25.
//


// swift-helloworld-main/HelloWorld/DLSKit/Operators/ConditionalOperators.swift
import Foundation

public class ConditionalOperators {
    public static func registerAll() {

        // Operator version of 'if' that RETURNS a value
        DSLOperatorRegistry.shared.register("Operator.if") { input, context in
            guard let dict = input as? [String: Any],
                  let conditionExpr = dict["condition"],
                  let thenExpr = dict["then"] // 'else' is optional
            else {
                //print("⚠️ Operator.if: Invalid input structure. Need 'condition' and 'then'. Input: \(String(describing: input))")
                return nil // Cannot evaluate without condition and then branch
            }

            // Evaluate the condition
            let conditionResult = DSLExpression.shared.evaluate(conditionExpr, context) as? Bool ?? false
            //print("--- DEBUG: Operator.if - Condition result: \(conditionResult)")

            if conditionResult {
                // If true, evaluate and return the 'then' branch
                let thenValue = DSLExpression.shared.evaluate(thenExpr, context)
                //print("--- DEBUG: Operator.if - Returning evaluated 'then' branch: \(String(describing: thenValue))")
                return thenValue
            } else {
                // If false, check for an 'else' branch
                if let elseExpr = dict["else"] {
                    let elseValue = DSLExpression.shared.evaluate(elseExpr, context)
                    //print("--- DEBUG: Operator.if - Returning evaluated 'else' branch: \(String(describing: elseValue))")
                    return elseValue
                } else {
                    // If no 'else' branch, return nil
                    //print("--- DEBUG: Operator.if - Condition false, no 'else' branch. Returning nil.")
                    return nil
                }
            }
        }

        // Add other conditional operators here if needed (e.g., switch/case)
    }
}
