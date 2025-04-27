import SwiftUI

public struct ZStackView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // Parâmetro de alinhamento para ZStack
        let rawAlign = node["alignment"]
        let alignStr = DSLExpression.shared.evaluate(rawAlign, context) as? String
        // Usa a mesma função mapAlignment que VStack/HStack (precisa estar acessível)
        let alignment: Alignment = mapAlignment(from: alignStr)

        let children = node["children"] as? [[String: Any]] ?? []
        var view = AnyView(
            ZStack(alignment: alignment) { // Cria o ZStack
                DSLViewRenderer.renderChildren(from: children, context: context)
            }
        )

        // Aplica modificadores
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            view = modifierRegistry.apply(modifiers, to: view, context: context)
        }
        return view
    }

    public static func register() {
        // Registra o componente zstack
        DSLComponentRegistry.shared.register("zstack", builder: render)

        // Registra modificadores comuns para ZStack (copiados/adaptados de VStack/HStack)

        modifierRegistry.register("padding") { view, paramsAny, context in
            let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)
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
                } else {
                    return AnyView(view.padding())
                }
            } else {
                return AnyView(view.padding())
            }
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
             let alignment: Alignment = mapAlignment(from: DSLExpression.shared.evaluate(params["alignment"], context) as? String)
             return AnyView(view.frame(minWidth: minWidth, idealWidth: idealWidth, maxWidth: maxWidth, minHeight: minHeight, idealHeight: idealHeight, maxHeight: maxHeight, alignment: alignment))
        }
        
        modifierRegistry.register("background") { view, paramsAny, context in
             let colorHex = DSLExpression.shared.evaluate(paramsAny, context) as? String
             if(colorHex == nil || colorHex == ""){ return view }
             let color = Color(hex: colorHex!) ?? .clear
             return AnyView(view.background(color))
         }

        modifierRegistry.register("opacity") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            let value = max(0.0, min(1.0, raw as? Double ?? 1.0))
            return AnyView(view.opacity(value))
        }

        modifierRegistry.register("ignoresSafeArea") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let ignore = evaluatedValue as? Bool, ignore {
                 return AnyView(view.ignoresSafeArea())
            } else if let edgesArray = evaluatedValue as? [String] {
                var edgeSet: Edge.Set = []
                for edgeStr in edgesArray {
                    switch edgeStr.lowercased() {
                    case "top": edgeSet.insert(.top); case "bottom": edgeSet.insert(.bottom); case "leading": edgeSet.insert(.leading); case "trailing": edgeSet.insert(.trailing); case "horizontal": edgeSet.insert(.horizontal); case "vertical": edgeSet.insert(.vertical); case "all": edgeSet.insert(.all); default: break
                    }
                }
                if !edgeSet.isEmpty {
                    return AnyView(view.ignoresSafeArea(.all, edges: edgeSet))
                }
            } 
            return view
        }
        
        // Adicionar outros modificadores relevantes (cornerRadius, clipShape, etc.) aqui se necessário
    }
} 