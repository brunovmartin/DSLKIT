import SwiftUI

public struct ProgressViewComponent {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        let valueExpr = node["value"]
        let value = DSLExpression.shared.evaluate(valueExpr, context) as? Double ?? 0.0
        let totalExpr = node["total"]
        let total = DSLExpression.shared.evaluate(totalExpr, context) as? Double ?? 1.0

        var view: AnyView

        view = AnyView(
            SwiftUI.ProgressView(value: value, total: total)
        )

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
