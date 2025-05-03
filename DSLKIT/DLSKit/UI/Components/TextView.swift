import SwiftUI

public struct TextView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        let textValue = node["value"]
        // let currentIndex = node["_currentIndex"] as? Int // Não é mais lido diretamente aqui

        // Avalia a expressão. DSLExpression usará context.currentIndex internamente se necessário.
        let evaluatedValue = DSLExpression.shared.evaluate(textValue, context) // Passa o contexto recebido

        let textToDisplay: String
        if let actualValue = evaluatedValue {
            textToDisplay = (String(describing: actualValue))
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
        
        // Aplicar modificadores de ação diretamente do node
        view = applyActionModifiers(node: node, context: context, to: view)
        
        return view
    }

    // --- Manter register() e todos os modificadores como estão ---
    public static func register() {
        DSLComponentRegistry.shared.register("text", builder: render)
        
        // Registra modificadores de base comuns (padding, background, etc.)
        registerBaseViewModifiers(on: modifierRegistry)
        
        // --- Modificadores Específicos de Texto ---
        
        modifierRegistry.register("font") { view, paramsAny, context in
            let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)
            // Caso 1: String (nome do estilo)
            if let styleName = evaluatedParams as? String {
                if let textStyle = mapTextStyle(from: styleName) {
                    return AnyView(view.font(.system(textStyle)))
                } else {
                    return AnyView(view.font(.body)) // Fallback
                }
            }
            // Caso 2: Dicionário (para size/weight/design)
            else if let paramsDict = evaluatedParams as? [String: Any] {
                if let styleName = paramsDict["style"] as? String, let textStyle = mapTextStyle(from: styleName) {
                     return AnyView(view.font(.system(textStyle)))
                }
                else if paramsDict["size"] != nil || paramsDict["weight"] != nil || paramsDict["design"] != nil {
                    let sizeVal = DSLExpression.shared.evaluate(paramsDict["size"], context)
                    let weightStr = DSLExpression.shared.evaluate(paramsDict["weight"], context) as? String
                    let designStr = DSLExpression.shared.evaluate(paramsDict["design"], context) as? String
                    let size = castToCGFloat(sizeVal) ?? Font.TextStyle.body.size
                    let weight = mapFontWeight(weightStr) ?? .regular
                    let design: Font.Design = {
                        if #available(iOS 16.1, macOS 13.0, tvOS 16.1, watchOS 9.1, *) {
                            return mapFontDesign(designStr) ?? .default
                        } else {
                            return .default
                        }
                    }()
                    return AnyView(view.font(.system(size: size, weight: weight, design: design)))
                }
                else {
                    return AnyView(view.font(.body)) // Fallback
                }
            }
            else {
                return AnyView(view.font(.body)) // Fallback
            }
        }
        
        // foreground movido para registerBaseViewModifiers
        
        modifierRegistry.register("strikethrough") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            var active = false
            var color: Color? = nil
            if let bool = raw as? Bool { active = bool }
            else if let dict = raw as? [String: Any] {
                active = DSLExpression.shared.evaluate(dict["active"], context) as? Bool ?? true
                color = parseColor(DSLExpression.shared.evaluate(dict["color"], context))
            }
            return AnyView(view.strikethrough(active, color: color))
        }

        modifierRegistry.register("underline") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            var active = false
            var color: Color? = nil
            if let bool = raw as? Bool { active = bool }
            else if let dict = raw as? [String: Any] {
                active = DSLExpression.shared.evaluate(dict["active"], context) as? Bool ?? true
                color = parseColor(DSLExpression.shared.evaluate(dict["color"], context))
            }
             return AnyView(view.underline(active, color: color))
        }

        modifierRegistry.register("lineLimit") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            if raw is NSNull { // Permitir nil para remover limite
                 if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                     return AnyView(view.lineLimit(nil))
                 } else {
                     return AnyView(view.lineLimit(Int.max)) // Fallback
                 }
            } else if let limit = raw as? Int {
                return AnyView(view.lineLimit(max(0, limit))) // Evitar limite negativo
            // Permitir dict { "limit": Int? }?
            //} else if let dict = raw as? [String: Any], let limit = DSLExpression.shared.evaluate(dict["limit"], context) as? Int {
            //     return AnyView(view.lineLimit(max(0, limit)))
            } else {
                 print("⚠️ LineLimit: Valor inválido \(String(describing: raw)). Esperado Int ou null.")
            }
            return view
        }

        modifierRegistry.register("lineSpacing") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            let spacing = castToCGFloat(raw) ?? 0 // Usa helper, default 0
            return AnyView(view.lineSpacing(spacing))
        }

        modifierRegistry.register("allowsTightening") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            let enabled = (raw as? Bool) == true
            return AnyView(view.allowsTightening(enabled))
        }

        modifierRegistry.register("minimumScaleFactor") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context)
            let factor = castToCGFloat(raw) ?? 1.0 // Default 1.0 (sem escala)
            return AnyView(view.minimumScaleFactor(min(max(0, factor), 1))) // Garante 0...1
        }

        modifierRegistry.register("truncationMode") { view, paramsAny, context in
            let raw = DSLExpression.shared.evaluate(paramsAny, context) as? String ?? "tail"
            let mode: Text.TruncationMode = {
                switch raw.lowercased() {
                case "head": return .head
                case "middle": return .middle
                default: return .tail // Inclui "tail" e desconhecidos
                }
            }()
            return AnyView(view.truncationMode(mode))
        }
        
        // Outros modificadores comuns de texto que podem ser adicionados:
        // - bold()
        // - italic()
        // - kerning() / tracking()
        // - baselineOffset()
        // - multilineTextAlignment()
        // - textCase()
    }
}
