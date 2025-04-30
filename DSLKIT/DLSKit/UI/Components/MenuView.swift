import SwiftUI

public struct MenuView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // Extrai o título do menu
        let titleExpr = node["title"]
        let title = DSLExpression.shared.evaluate(titleExpr, context) as? String ?? "Menu"
        
        // Extrai os filhos (itens do menu)
        let children = node["children"] as? [[String: Any]] ?? []
        
        // Cria o Menu base
        var menuView = AnyView(
            Menu(title) {
                ForEach(0..<children.count, id: \.self) { i in
                    DSLViewRenderer.renderComponent(from: children[i], context: context)
                }
            }
        )

        // Aplica modificadores
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            menuView = modifierRegistry.apply(modifiers, to: menuView, context: context)
        }
        
        // Aplicar modificadores de ação diretamente do node
        menuView = applyActionModifiers(node: node, context: context, to: menuView)
        
        return menuView
    }

    public static func register() {
        DSLComponentRegistry.shared.register("menu", builder: render)
        
        // Registra modificadores de base comuns
        registerBaseViewModifiers(on: modifierRegistry)
        
        // Modificador específico para estilização do menu
        modifierRegistry.register("menuStyle") { view, value, context in
            let styleName = DSLExpression.shared.evaluate(value, context) as? String
            switch styleName?.lowercased() {
            case "default":
                return AnyView(view.menuStyle(.automatic))
            case "button":
                return AnyView(view.menuStyle(.button))
            default:
                return view
            }
        }
    }
} 
