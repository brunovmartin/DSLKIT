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
        
        // Aplicar modificadores de ação diretamente do node
        view = applyActionModifiers(node: node, context: context, to: view)
        
        return view
    }

    public static func register() {
        // Registra o componente zstack
        DSLComponentRegistry.shared.register("zstack", builder: render)

        // Registra modificadores de base comuns
        registerBaseViewModifiers(on: modifierRegistry)

        // Modificadores específicos de ZStack (se houver algum no futuro)
        // Ex: modifierRegistry.register("specificZStackMod", ...)
        
        // O modificador 'alignment' é tratado no render() para ZStack, não registrado aqui.
    }
} 