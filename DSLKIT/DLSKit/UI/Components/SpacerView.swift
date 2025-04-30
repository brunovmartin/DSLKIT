import SwiftUI

public struct SpacerView {
    // Spacer geralmente não precisa de modificadores próprios,
    // mas podemos usar os básicos se necessário (raro).
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // O Spacer do SwiftUI pode aceitar um minLength opcional.
        // Vamos ler do nó JSON.
        let minLengthExpr = node["minLength"]
        let minLength = DSLExpression.shared.evaluate(minLengthExpr, context) as? CGFloat

        var view = AnyView(Spacer(minLength: minLength))

        // Aplicar modificadores básicos se houver (embora incomum para Spacer)
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            view = modifierRegistry.apply(modifiers, to: view, context: context)
        }
        
        // Aplicar modificadores de ação diretamente do node (ainda mais incomum para Spacer)
        view = applyActionModifiers(node: node, context: context, to: view)

        return view
    }

    public static func register() {
        DSLComponentRegistry.shared.register("spacer", builder: render)
        
        // Registra modificadores de base comuns, caso sejam úteis em algum cenário.
        registerBaseViewModifiers(on: modifierRegistry)
    }
} 