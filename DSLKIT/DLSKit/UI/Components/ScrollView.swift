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

        return finalView
    }

    public static func register() {
        DSLComponentRegistry.shared.register("scrollview", builder: render)

        // Register relevant modifiers for ScrollView
        // Common ones like frame, padding, background are useful

        modifierRegistry.register("padding") { view, paramsAny, context in
           let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)
           // (Implementation copied from HStackView/VStackView)
           if evaluatedParams is NSNull || (evaluatedParams as? [String: Any])?.isEmpty == true || (evaluatedParams as? Bool) == true {
               return AnyView(view.padding())
           } else if let length = castToCGFloat(evaluatedParams) {
               return AnyView(view.padding(length))
           } else if let paramsDict = evaluatedParams as? [String: Any] {
               if let edgesList = paramsDict["edges"] as? [String], let lengthValue = paramsDict["length"] {
                   let edges = mapEdgeSet(from: edgesList)
                   let length = castToCGFloat(lengthValue) ?? 0
                   return AnyView(view.padding(edges, length))
               } else if paramsDict.keys.contains(where: { ["top", "leading", "bottom", "trailing"].contains($0) }) {
                   let top = castToCGFloat(paramsDict["top"])
                   let leading = castToCGFloat(paramsDict["leading"])
                   let bottom = castToCGFloat(paramsDict["bottom"])
                   let trailing = castToCGFloat(paramsDict["trailing"])
                   let insets = EdgeInsets(top: top ?? 0, leading: leading ?? 0, bottom: bottom ?? 0, trailing: trailing ?? 0)
                   return AnyView(view.padding(insets))
               } else { return AnyView(view.padding()) }
           }
           return AnyView(view.padding())
       }

       modifierRegistry.register("frame") { view, paramsAny, context in
           let params = paramsAny as? [String: Any] ?? [:]
           func parseDimension(_ key: String) -> CGFloat? {
               guard let value = params[key] else { return nil }
               let evaluatedValue = DSLExpression.shared.evaluate(value, context)
               if let stringValue = evaluatedValue as? String, stringValue.lowercased() == ".infinity" { return .infinity }
               else if let number = evaluatedValue as? NSNumber { return CGFloat(number.doubleValue) }
               else if let cgFloat = evaluatedValue as? CGFloat { return cgFloat }
               return nil
           }
           let minWidth = parseDimension("minWidth")
           let idealWidth = parseDimension("width")
           let maxWidth = parseDimension("maxWidth")
           let minHeight = parseDimension("minHeight")
           let idealHeight = parseDimension("height")
           let maxHeight = parseDimension("maxHeight")
           let alignmentString = DSLExpression.shared.evaluate(params["alignment"], context) as? String
           let alignment: Alignment = mapAlignment(from: alignmentString)
           return AnyView(view.frame(minWidth: minWidth, idealWidth: idealWidth, maxWidth: maxWidth, minHeight: minHeight, idealHeight: idealHeight, maxHeight: maxHeight, alignment: alignment))
       }

       modifierRegistry.register("background") { view, paramsAny, context in
           let colorHex = DSLExpression.shared.evaluate(paramsAny, context) as? String
           if(colorHex == nil || colorHex == ""){ return view }
           let color = Color(hex: colorHex!) ?? .clear
           return AnyView(view.background(color))
       }

        // Add other relevant modifiers like cornerRadius if needed
        modifierRegistry.register("cornerRadius") { view, paramsAny, context in
             let radius = DSLExpression.shared.evaluate(paramsAny, context) as? CGFloat ?? 0
             return AnyView(view.cornerRadius(radius)) // Standard cornerRadius works on ScrollView
         }
    }
}

// **IMPORTANT NOTE ON 'forEach'**:
// The current ScrollViewComponent assumes DSLViewRenderer.renderComponent can handle
// the nested 'forEach' structure defined within the 'content' node in the JSON.
// This likely requires `DSLViewRenderer` or a dedicated `ForEachComponent` to be aware
// of the 'forEach', 'data', and 'itemTemplate' keys, perform the iteration,
// substitute 'currentItem.*' paths, and render the template for each item.
// If that logic isn't present, the ScrollView's content will not render correctly.
