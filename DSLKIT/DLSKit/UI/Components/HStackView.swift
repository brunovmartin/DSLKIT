import SwiftUI

public struct HStackView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        let rawAlign = node["alignment"]
        let alignStr = DSLExpression.shared.evaluate(rawAlign, context) as? String
        let vAlignment: VerticalAlignment = {
            switch alignStr?.lowercased() {
            case "bottom":   return .bottom
            case "center":   return .center
            case "firstTextBaseline":   return .firstTextBaseline
            case "lastTextBaseline":   return .lastTextBaseline
            case "top":   return .top
            default:         return .top
            }
        }()
        let rawSpacing = node["spacing"]
        let spacing = DSLExpression.shared.evaluate(rawSpacing, context) as? CGFloat

        let children = node["children"] as? [[String: Any]] ?? []
        var view = AnyView(
            HStack(alignment: vAlignment, spacing: spacing) {
                DSLViewRenderer.renderChildren(from: children, context: context)
            }
        )

        if let modifiers = node["modifiers"] as? [[String: Any]] {
            view = modifierRegistry.apply(modifiers, to: view, context: context)
        }
        return view
    }


    public static func register() {
        DSLComponentRegistry.shared.register("hstack", builder: render)

        modifierRegistry.register("padding") { view, paramsAny, context in
            let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)

            if evaluatedParams is NSNull || (evaluatedParams as? [String: Any])?.isEmpty == true || (evaluatedParams as? Bool) == true {
                return AnyView(view.padding())
            }
            else if let length = castToCGFloat(evaluatedParams) {
                return AnyView(view.padding(length))
            }
            else if let paramsDict = evaluatedParams as? [String: Any] {
                if let edgesList = paramsDict["edges"] as? [String], let lengthValue = paramsDict["length"] {
                    let edges = mapEdgeSet(from: edgesList)
                    let length = castToCGFloat(lengthValue) ?? 0
                    return AnyView(view.padding(edges, length))
                }
                else if paramsDict.keys.contains(where: { ["top", "leading", "bottom", "trailing"].contains($0) }) {
                    let top = castToCGFloat(paramsDict["top"])
                    let leading = castToCGFloat(paramsDict["leading"])
                    let bottom = castToCGFloat(paramsDict["bottom"])
                    let trailing = castToCGFloat(paramsDict["trailing"])
                    let insets = EdgeInsets(top: top ?? 0, leading: leading ?? 0, bottom: bottom ?? 0, trailing: trailing ?? 0)
                    return AnyView(view.padding(insets))
                }
                else {
                    return AnyView(view.padding())
                }
            }
            return AnyView(view.padding())
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

        modifierRegistry.register("layoutPriority") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]
            let priority = DSLExpression.shared.evaluate(params["priority"], context) as? Double ?? 0
            return AnyView(view.layoutPriority(priority))
        }

        modifierRegistry.register("clipShape") { view, paramsAny, context in
            return AnyView(view.clipShape(Circle()))
        }
        modifierRegistry.register("cornerRadius") { view, paramsAny, context in
            let radius = DSLExpression.shared.evaluate(paramsAny, context) as? CGFloat ?? 0
            return AnyView(view.cornerRadius(radius))
        }
        modifierRegistry.register("mask") { view, paramsAny, context in
            return AnyView(view.mask(EmptyView()))
        }

        modifierRegistry.register("background") { view, paramsAny, context in
            let colorHex = DSLExpression.shared.evaluate(paramsAny, context) as? String
            if(colorHex == nil || colorHex == ""){ return view }
            let color = Color(hex: colorHex!) ?? .clear
            return AnyView(view.background(color))
        }
        modifierRegistry.register("overlay") { view, paramsAny, context in
            return AnyView(view.overlay(EmptyView()))
        }

        modifierRegistry.register("opacity") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            let value = max(0.0, min(1.0, raw as? Double ?? 1.0))
            return AnyView(view.opacity(value))
        }

        modifierRegistry.register("shadow") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]
            let radius = DSLExpression.shared.evaluate(params["radius"], context) as? CGFloat ?? 0
            let x = DSLExpression.shared.evaluate(params["x"], context) as? CGFloat ?? 0
            let y = DSLExpression.shared.evaluate(params["y"], context) as? CGFloat ?? 0
            return AnyView(view.shadow(radius: radius, x: x, y: y))
        }
        modifierRegistry.register("blur") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]
            let radius = DSLExpression.shared.evaluate(params["radius"], context) as? CGFloat ?? 0
            return AnyView(view.blur(radius: radius))
        }

        modifierRegistry.register("offset") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]
            let x = DSLExpression.shared.evaluate(params["x"], context) as? CGFloat ?? 0
            let y = DSLExpression.shared.evaluate(params["y"], context) as? CGFloat ?? 0
            return AnyView(view.offset(x: x, y: y))
        }
        modifierRegistry.register("scaleEffect") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]
            let x = DSLExpression.shared.evaluate(params["x"], context) as? CGFloat ?? 1
            let y = DSLExpression.shared.evaluate(params["y"], context) as? CGFloat ?? 1
            return AnyView(view.scaleEffect(x: x, y: y))
        }
        modifierRegistry.register("rotationEffect") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]
            let angle = DSLExpression.shared.evaluate(params["angle"], context) as? Double ?? 0
            return AnyView(view.rotationEffect(.degrees(angle)))
        }

        modifierRegistry.register("onTapGesture") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]
            return AnyView(view.onTapGesture {
                DSLInterpreter.shared.handleEvent(params, context: context)
            })
        }
        modifierRegistry.register("onAppear") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]
            return AnyView(view.onAppear {
                DSLInterpreter.shared.handleEvent(params, context: context)
            })
        }
        modifierRegistry.register("onDisappear") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]
            return AnyView(view.onDisappear {
                DSLInterpreter.shared.handleEvent(params, context: context)
            })
        }

        modifierRegistry.register("accessibilityLabel") { view, paramsAny, context in
            let params = paramsAny as? [String: Any] ?? [:]
            let labelText = DSLExpression.shared.evaluate(params["label"], context) as? String ?? ""
            return AnyView(view.accessibilityLabel(Text(labelText)))
        }
    }
}
