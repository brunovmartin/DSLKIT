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
        
        // Aplicar modificadores de ação genéricos (onTapGesture, onAppear, etc.) diretamente do node
        // Nota: O "onTap" principal do botão já é tratado na inicialização.
        view = applyActionModifiers(node: node, context: context, to: view)

        return view
    }

    public static func register() {
        DSLComponentRegistry.shared.register("button", builder: render)

        // Registra modificadores de base comuns (padding, frame, background, opacity, cornerRadius)
        registerBaseViewModifiers(on: modifierRegistry)

        // --- Modificadores Específicos de Button ---

        // disabled é importante para botões
        modifierRegistry.register("disabled") { view, value, context in
            let isDisabled = DSLExpression.shared.evaluate(value, context) as? Bool ?? false
            return AnyView(view.disabled(isDisabled))
        }
        
        // tint pode afetar a aparência do botão dependendo do estilo
        modifierRegistry.register("tint") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let color = parseColor(evaluatedValue) {
                return AnyView(view.tint(color))
            }
            return view
        }
        
        // buttonStyle (Exemplo - implementação real pode variar)
        modifierRegistry.register("buttonStyle") { view, value, context in
            let styleName = DSLExpression.shared.evaluate(value, context) as? String
            switch styleName?.lowercased() {
            case "bordered":
                 if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    return AnyView(view.buttonStyle(.bordered))
                 } else {
                     return view // Fallback para OS mais antigo
                 }
            case "borderedProminent":
                 if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                     return AnyView(view.buttonStyle(.borderedProminent))
                 } else {
                     return view // Fallback
                 }
            case "borderless":
                 return AnyView(view.buttonStyle(.borderless))
            case "plain":
                 return AnyView(view.buttonStyle(.plain))
            // Adicione outros estilos conforme necessário
            default:
                return view
            }
        }
    }
}
