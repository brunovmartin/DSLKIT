//
//  ConditionalView.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 26/04/25.
//


// swift-helloworld-main/HelloWorld/DLSKit/UI/Components/ConditionalView.swift
import SwiftUI

public struct ConditionalView {

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        guard let conditionExpr = node["condition"] else {
            //print("⚠️ ConditionalView: Missing 'condition' expression.")
            return AnyView(EmptyView()) // Don't render if condition is missing
        }

        // Evaluate the condition
        let shouldRender = DSLExpression.shared.evaluate(conditionExpr, context) as? Bool ?? false
        //print("--- DEBUG: ConditionalView - Condition evaluated to: \(shouldRender)")

        if shouldRender {
            // If true, get the content node definition
            guard let contentNode = node["content"] as? [String: Any] else {
                //print("⚠️ ConditionalView: Missing 'content' node definition when condition is true.")
                return AnyView(Text("Error: Conditional content missing")) // Show error if content missing
            }
            //print("--- DEBUG: ConditionalView - Rendering content node: \(contentNode)")
            // Render the content component
            return DSLViewRenderer.renderComponent(from: contentNode, context: context)
        } else {
            // If false, render nothing
            //print("--- DEBUG: ConditionalView - Condition false, rendering EmptyView.")
            return AnyView(EmptyView())
        }
    }

    public static func register() {
        DSLComponentRegistry.shared.register("conditional", builder: render)
        // No specific modifiers needed for ConditionalView itself usually
    }
}
