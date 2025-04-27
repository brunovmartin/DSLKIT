// ButtonView.swift

import SwiftUI

public struct ButtonView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        let titleExpr = node["title"]
        let title = DSLExpression.shared.evaluate(titleExpr, context) as? String ?? ""
        let action = node["onTap"]

        var view = AnyView(
            Button(action: {
                if let onTap = action {
                    DSLInterpreter.shared.handleEvent(onTap, context: context)
                }
            }) {
                if let children = node["children"] as? [[String: Any]] {
                    DSLViewRenderer.renderChildren(from: children, context: context)
                }else {
                    Text(title)
                }
            }
        )

        if let modifiers = node["modifiers"] as? [[String: Any]] {
            view = modifierRegistry.apply(modifiers, to: view, context: context)
        }

        return view
    }

    public static func register() {
        DSLComponentRegistry.shared.register("button", builder: render)

        modifierRegistry.register("padding") { view, value, _ in
            if let length = castToCGFloat(value) {
                return AnyView(view.padding(length))
            } else if let dict = value as? [String: Any] {
                let edges = mapEdgeSet(from: dict["edges"] as? [String])
                let length = castToCGFloat(dict["length"])
                return AnyView(view.padding(edges, length ?? 0))
            } else if value is NSNull || (value as? [String: Any])?.isEmpty == true {
                return AnyView(view.padding())
            } else if let boolValue = value as? Bool, boolValue {
                return AnyView(view.padding())
            }
            return view
        }

        modifierRegistry.register("background") { view, value, _ in
            if let color = parseColor(value) {
                return AnyView(view.background(color))
            }
            return view
        }
        
        modifierRegistry.register("frame") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]

            func parseDimension(_ key: String) -> CGFloat? {
                guard let value = params[key] else { return nil }
                let evaluatedValue = DSLExpression.shared.evaluate(value, context)
                if let stringValue = evaluatedValue as? String, stringValue.lowercased() == ".infinity" {
                    return .infinity
                } else if let number = evaluatedValue as? NSNumber {
                    return CGFloat(number.doubleValue)
                } else if let cgFloat = evaluatedValue as? CGFloat {
                     return cgFloat
                }
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

            return AnyView(view.frame(
                minWidth: minWidth,
                idealWidth: idealWidth,
                maxWidth: maxWidth,
                minHeight: minHeight,
                idealHeight: idealHeight,
                maxHeight: maxHeight,
                alignment: alignment
            ))
        }
        
        modifierRegistry.register("foreground") { view, value, _ in
            if let color = parseColor(value) {
                return AnyView(view.foregroundColor(color))
            }
            return view
        }

        modifierRegistry.register("cornerRadius") { view, value, _ in
            guard let radius = castToCGFloat(value) else { return view }
            return AnyView(view.cornerRadius(radius))
        }

        modifierRegistry.register("opacity") { view, value, _ in
            guard let opacityValue = value as? Double else { return view }
            return AnyView(view.opacity(max(0.0, min(1.0, opacityValue))))
        }
    }
}
