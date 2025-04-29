//
//  ScrollViewComponent.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 26/04/25.
//


// swift-helloworld-main/HelloWorld/DLSKit/UI/Components/ScrollViewComponent.swift
import SwiftUI

public struct ScrollViewComponent {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // Determine scroll axis
        let axisString = DSLExpression.shared.evaluate(node["axis"], context) as? String ?? "vertical"
        let axis: Axis.Set = axisString.lowercased() == "horizontal" ? .horizontal : .vertical

        // Determine if indicators should be shown
        let showsIndicators = DSLExpression.shared.evaluate(node["showsIndicators"], context) as? Bool ?? true

        // Get the content node which defines what's inside the ScrollView
        guard let contentNode = node["content"] as? [String: Any] else {
            print("⚠️ ScrollViewComponent: Missing 'content' node definition.")
            return AnyView(Text("ScrollView Error: Content missing"))
        }

        // Create the ScrollView
        let scrollView = ScrollView(axis, showsIndicators: showsIndicators) {
            // Render the content node inside the ScrollView
            // IMPORTANT: The content node itself might be a VStack, HStack, or importantly,
            // a structure containing a 'forEach' loop as defined in the weather JSON.
            // DSLViewRenderer.renderComponent needs to handle rendering whatever 'contentNode' defines.
            // If 'contentNode' has a 'forEach', `renderComponent` would need to resolve that.
            // Let's assume renderComponent can handle basic types like VStack/HStack defined within content.
            // Handling the 'forEach' structure might require enhancing renderComponent or introducing
            // a dedicated looping component type.

            // For now, directly render the content node:
            DSLViewRenderer.renderComponent(from: contentNode, context: context)
        }

        var finalView = AnyView(scrollView)

        // Apply common modifiers (frame, padding, background, etc.)
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            finalView = modifierRegistry.apply(modifiers, to: finalView, context: context)
        }
        
        // Aplicar modificadores de ação diretamente do node
        finalView = applyActionModifiers(node: node, context: context, to: finalView)

        return finalView
    }

    public static func register() {
        DSLComponentRegistry.shared.register("scrollview", builder: render)

        // Registra modificadores de base comuns (frame, padding, background, cornerRadius, etc.)
        registerBaseViewModifiers(on: modifierRegistry)

        // Modificadores específicos de ScrollView (se houver no futuro)
        // Ex: scrollDisabled, contentMargins, etc.
        
        // Nota: 'axis' e 'showsIndicators' são tratados no render()
    }
}

// **IMPORTANT NOTE ON 'forEach'**:
// The current ScrollViewComponent assumes DSLViewRenderer.renderComponent can handle
// the nested 'forEach' structure defined within the 'content' node in the JSON.
// This likely requires `DSLViewRenderer` or a dedicated `ForEachComponent` to be aware
// of the 'forEach', 'data', and 'itemTemplate' keys, perform the iteration,
// substitute 'currentItem.*' paths, and render the template for each item.
// If that logic isn't present, the ScrollView's content will not render correctly.
