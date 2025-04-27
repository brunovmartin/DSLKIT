import SwiftUI

public struct TextView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        var rawValue = node["value"] // Original expression { "var": "items[currentItemIndex]" } or literal
        let currentIndex = node["_currentIndex"] as? Int // Check if index was injected by ListView

        // --- START MODIFICATION ---
        // If we have an index AND the value expression is a variable path referencing the placeholder...
        if let index = currentIndex,
           let valueDict = rawValue as? [String: Any],
           var path = valueDict["var"] as? String, // Get the path string
           path.contains("[currentItemIndex]")      // Check if it uses the placeholder
        {
            // ...substitute the actual index into the path string BEFORE evaluation.
            let actualPath = path.replacingOccurrences(of: "[currentItemIndex]", with: "[\(index)]")
            // Update rawValue to be the new dictionary with the substituted path
            rawValue = ["var": actualPath] // Now rawValue is e.g., { "var": "items[123]" }
            //print("--- TextView: Substituted index \(index) into path. New rawValue: \(String(describing: rawValue))")
        }
        // --- END MODIFICATION ---

        // Now evaluate the (potentially modified) rawValue expression
        let evaluatedValue = DSLExpression.shared.evaluate(rawValue, context)

        let textToDisplay: String
        if let actualValue = evaluatedValue {
            textToDisplay = "\(actualValue)"
        } else {
            textToDisplay = ""
        }

        //print("--- DEBUG: TextView evaluated value: \(textToDisplay)")
        var view = AnyView(Text(textToDisplay))

        if let modifiers = node["modifiers"] as? [[String: Any]] {
            // IMPORTANT: Modifiers might ALSO need index awareness if they use [currentItemIndex]
            // For now, assume modifiers don't depend on the index in this simple example.
            // If they did, you'd need to pass the index into modifierRegistry.apply or handle it within evaluate.
            view = modifierRegistry.apply(modifiers, to: view, context: context)
        }
        return view
    }

    // --- Manter register() e todos os modificadores como estão ---
    public static func register() {
        DSLComponentRegistry.shared.register("text", builder: render)
        
        
        modifierRegistry.register("font") { view, paramsAny, context in
            let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)

            // Caso 1: String (nome do estilo)
            if let styleName = evaluatedParams as? String {
                if let textStyle = mapTextStyle(from: styleName) {
                    //print("--- DEBUG: Applying font text style: \(styleName)")
                    return AnyView(view.font(.system(textStyle))) // Usar .system(textStyle) é mais flexível
                } else {
                    //print("--- DEBUG: Applying default font (unknown style: \(styleName))")
                    return AnyView(view.font(.body)) // Fallback para estilo desconhecido
                }
            }
            // Caso 2: Dicionário (para size/weight/design)
            else if let paramsDict = evaluatedParams as? [String: Any] {
                // Tenta pegar estilo primeiro
                if let styleName = paramsDict["style"] as? String, let textStyle = mapTextStyle(from: styleName) {
                     //print("--- DEBUG: Applying font text style from dict: \(styleName)")
                     // TODO: Adicionar lógica para aplicar weight/design sobre o textStyle se necessário e possível
                     return AnyView(view.font(.system(textStyle)))

                }
                // Senão, tenta usar .system com size/weight/design
                else if paramsDict["size"] != nil || paramsDict["weight"] != nil || paramsDict["design"] != nil {
                    let sizeVal = DSLExpression.shared.evaluate(paramsDict["size"], context)
                    let weightStr = DSLExpression.shared.evaluate(paramsDict["weight"], context) as? String
                    let designStr = DSLExpression.shared.evaluate(paramsDict["design"], context) as? String

                    // Usa tamanho do body como fallback se não especificado
                    let size = castToCGFloat(sizeVal) ?? Font.TextStyle.body.size
                    let weight = mapFontWeight(weightStr) ?? .regular // Requer ModifierHelpers.swift
                    let design: Font.Design = { // Requer ModifierHelpers.swift e @available
                        if #available(iOS 16.1, macOS 13.0, tvOS 16.1, watchOS 9.1, *) {
                            return mapFontDesign(designStr) ?? .default
                        } else {
                            return .default
                        }
                    }()

                    //print("--- DEBUG: Applying system font: Size=\(size), Weight=\(String(describing: weightStr)), Design=\(String(describing: designStr))")
                    return AnyView(view.font(.system(size: size, weight: weight, design: design)))
                }
                // Dicionário inválido ou vazio
                else {
                     //print("--- DEBUG: Applying default font (invalid font dictionary)")
                    return AnyView(view.font(.body))
                }
            }
             // Caso 3: Fallback geral
            else {
                //print("--- DEBUG: Applying default font (invalid font parameter type)")
                return AnyView(view.font(.body))
            }
        }
        
        modifierRegistry.register("padding") { view, paramsAny, context in
            // Avalia o valor do JSON primeiro
            let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)

            // Caso 1: Padding padrão (ex: "padding": true ou "padding": {})
            if evaluatedParams is NSNull || (evaluatedParams as? [String: Any])?.isEmpty == true || (evaluatedParams as? Bool) == true {
                //print("--- DEBUG: Applying default padding")
                return AnyView(view.padding())
            }
            // Caso 2: Padding uniforme (ex: "padding": 10)
            else if let length = castToCGFloat(evaluatedParams) { // Usa sua função helper existente
                //print("--- DEBUG: Applying uniform padding: \(length)")
                return AnyView(view.padding(length))
            }
            // Caso 3: Dicionário especificando edges/length ou top/leading etc.
            else if let paramsDict = evaluatedParams as? [String: Any] {
                // Subcaso 3a: Edges + Length (ex: {"edges": ["horizontal"], "length": 10})
                if let edgesList = paramsDict["edges"] as? [String], let lengthValue = paramsDict["length"] {
                    let edges = mapEdgeSet(from: edgesList) // Usa sua função helper existente
                    let length = castToCGFloat(lengthValue) ?? 0 // Usa sua função helper existente
                    //print("--- DEBUG: Applying padding to edges: \(edgesList) with length: \(length)")
                    return AnyView(view.padding(edges, length))
                }
                // Subcaso 3b: Edge individuais (ex: {"top": 5, "leading": 10})
                else if paramsDict.keys.contains(where: { ["top", "leading", "bottom", "trailing"].contains($0) }) {
                    let top = castToCGFloat(paramsDict["top"])
                    let leading = castToCGFloat(paramsDict["leading"])
                    let bottom = castToCGFloat(paramsDict["bottom"])
                    let trailing = castToCGFloat(paramsDict["trailing"])
                    let insets = EdgeInsets(top: top ?? 0, leading: leading ?? 0, bottom: bottom ?? 0, trailing: trailing ?? 0)
                    //print("--- DEBUG: Applying specific edge insets: T:\(top ?? 0) L:\(leading ?? 0) B:\(bottom ?? 0) T:\(trailing ?? 0)")
                    return AnyView(view.padding(insets))
                }
                // Se for um dicionário, mas não corresponder aos padrões acima, aplica padding padrão
                else {
                    //print("--- DEBUG: Applying default padding (unrecognized dictionary)")
                    return AnyView(view.padding())
                }
            }

            // Se não for nenhum dos casos acima, não aplica padding ou aplica padrão
            //print("--- DEBUG: Padding - No valid format recognized, applying default padding.")
            return AnyView(view.padding())
        }


        // MARK: - Decoration
        
        modifierRegistry.register("background") { view, value, _ in
            if let color = parseColor(value) {
                return AnyView(view.background(color))
            }
            return view
        }
        
        modifierRegistry.register("foreground") { view, value, _ in
            if let color = parseColor(value) {
                return AnyView(view.foregroundColor(color))
            }
            return view
        }
        
        modifierRegistry.register("strikethrough") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            var active = false
            var color: Color? = nil
            if let bool = raw as? Bool {
                active = bool
            } else if let dict = raw as? [String: Any] {
                active = DSLExpression.shared.evaluate(dict["active"], context) as? Bool ?? true
                let rawColor = DSLExpression.shared.evaluate(dict["color"], context)
                color = parseColor(rawColor)
            }
            return AnyView(view.strikethrough(active, color: color))
        }

        modifierRegistry.register("underline") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            var active = false
            var color: Color? = nil
            if let bool = raw as? Bool {
                active = bool
            } else if let dict = raw as? [String: Any] {
                active = DSLExpression.shared.evaluate(dict["active"], context) as? Bool ?? true
                let rawColor = DSLExpression.shared.evaluate(dict["color"], context)
                color = parseColor(rawColor)
            }
            return AnyView(view.underline(active, color: color))
        }

        // MARK: - Layout & Metrics
        modifierRegistry.register("lineLimit") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            if raw is NSNull {
                return AnyView(view.lineLimit(nil))
            } else if let dict = raw as? [String: Any] {
                let limit = DSLExpression.shared.evaluate(dict["limit"], context) as? Int
                return AnyView(view.lineLimit(limit))
            } else if let limit = raw as? Int {
                return AnyView(view.lineLimit(limit))
            }
            return view
        }

        modifierRegistry.register("lineSpacing") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            let spacing = castToCGFloat(raw) ?? 0
            return AnyView(view.lineSpacing(spacing))
        }

        modifierRegistry.register("allowsTightening") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            let enabled = (raw as? Bool) == true
            return AnyView(view.allowsTightening(enabled))
        }

        modifierRegistry.register("minimumScaleFactor") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            let factor = castToCGFloat(raw) ?? 1
            return AnyView(view.minimumScaleFactor(min(max(0, factor), 1)))
        }

        modifierRegistry.register("truncationMode") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context) as? String ?? "tail"
            let mode: Text.TruncationMode = {
                switch raw.lowercased() {
                case "head": return .head
                case "middle": return .middle
                default: return .tail
                }
            }()
            return AnyView(view.truncationMode(mode))
        }
    }
}
