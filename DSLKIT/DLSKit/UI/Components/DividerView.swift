//
//  DividerView.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 26/04/25.
//


// swift-helloworld-main/HelloWorld/DLSKit/UI/Components/DividerView.swift
import SwiftUI

public struct DividerView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // A SwiftUI Divider is quite simple
        let divider = Divider()

        // Wrap in AnyView before applying modifiers
        var finalView = AnyView(divider)

        // Apply common modifiers (like padding, background color for thickness, etc.)
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            finalView = modifierRegistry.apply(modifiers, to: finalView, context: context)
        }

        return finalView
    }

    public static func register() {
        DSLComponentRegistry.shared.register("divider", builder: render)

        // Register relevant modifiers for Divider
        // Often padding, frame(height:), background are used to style dividers

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
           let idealHeight = parseDimension("height") // Useful for divider thickness
           let maxHeight = parseDimension("maxHeight")
           let alignmentString = DSLExpression.shared.evaluate(params["alignment"], context) as? String
           let alignment: Alignment = mapAlignment(from: alignmentString)
           return AnyView(view.frame(minWidth: minWidth, idealWidth: idealWidth, maxWidth: maxWidth, minHeight: minHeight, idealHeight: idealHeight, maxHeight: maxHeight, alignment: alignment))
       }

       modifierRegistry.register("background") { view, paramsAny, context in
           let colorHex = DSLExpression.shared.evaluate(paramsAny, context) as? String
           if(colorHex == nil || colorHex == ""){ return view }
           // Note: Applying background to Divider changes its appearance significantly.
           // Often used with frame(height: 1) to create a custom colored line.
           let color = Color(hex: colorHex!) ?? .clear
           return AnyView(view.background(color))
       }
    }
}