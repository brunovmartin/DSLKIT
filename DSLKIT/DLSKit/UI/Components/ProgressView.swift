import SwiftUI

public struct ProgressViewComponent {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        let valueExpr = node["value"]
        let valueAny = DSLExpression.shared.evaluate(valueExpr, context)
        let totalExpr = node["total"]
        let totalAny = DSLExpression.shared.evaluate(totalExpr, context)

        // Tenta converter para Double via NSNumber (aceita Int, Double, etc.)
        let valueDouble = (valueAny as? NSNumber)?.doubleValue
        let totalDouble = (totalAny as? NSNumber)?.doubleValue ?? 1.0 // Default total 1.0 se não especificado ou inválido

        var view: AnyView

        // Usa ProgressView com valor/total se value foi convertido com sucesso
        if let finalValue = valueDouble {
             print("--- DEBUG: ProgressView render - value: \\(finalValue), total: \\(totalDouble)")
            view = AnyView(
                SwiftUI.ProgressView(value: finalValue, total: totalDouble)
            )
        } else {
            // Se value falhou a conversão, usa ProgressView indeterminado
            print("--- DEBUG: ProgressView render - indeterminate (value eval: \\(String(describing: valueAny)))")
            view = AnyView(
                SwiftUI.ProgressView()
            )
        }

        if let modifiers = node["modifiers"] as? [[String: Any]] {
            view = modifierRegistry.apply(modifiers, to: view, context: context)
        }

        return view
    }

    public static func register() {
        DSLComponentRegistry.shared.register("progress", builder: render)

        // Registra modificadores de base comuns
        registerBaseViewModifiers(on: modifierRegistry)

        // --- Modificadores Específicos de ProgressView ---

        // Modificador para definir a cor do progresso
        modifierRegistry.register("tint") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let color = parseColor(evaluatedValue) {
                return AnyView(view.tint(color))
            }
            return view
        }

        // Modificador para definir o estilo do progresso
        modifierRegistry.register("style") { view, value, context in
            let styleName = DSLExpression.shared.evaluate(value, context) as? String
            switch styleName?.lowercased() {
            case "circular":
                return AnyView(view.progressViewStyle(CircularProgressViewStyle()))
            case "linear":
                return AnyView(view.progressViewStyle(LinearProgressViewStyle()))
            default:
                return view
            }
        }

        // Modificador para definir o frame do progresso
        modifierRegistry.register("frame") { view, value, context in
            if let frameDict = DSLExpression.shared.evaluate(value, context) as? [String: Any] {
                let width = frameDict["width"] as? CGFloat
                let height = frameDict["height"] as? CGFloat
                return AnyView(view.frame(width: width, height: height))
            }
            return view
        }
    }
} 
