import SwiftUI

public struct ToggleView {
    // 1. Adiciona um Modifier Registry específico para ToggleView
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        let labelText = DSLExpression.shared.evaluate(node["label"], context) as? String ?? ""
        let onChangeAction = node["onChange"]
        
        // Busca a variável de estado na raiz do nó
        guard let varName = node["var"] as? String else {
            print("⚠️ ToggleView: Parâmetro 'var' (String) faltando na raiz do nó.")
            return AnyView(Text("Toggle Error: var missing"))
        }
        
        // Cria o Binding usando a variável da raiz e passando a ação
        let isOnBinding: Binding<Bool> = BindingResolver.bind(
            varName, 
            context: context, 
            defaultValue: false, // Assume false se não existir
            onChangeAction: onChangeAction 
        )
        
        print("--- DEBUG: ToggleView render - Root var: \(varName), current value: \(isOnBinding.wrappedValue)")

        // Cria a view base (sem modificador .onChange)
        let toggle = Toggle(labelText, isOn: isOnBinding)

        var finalView = AnyView(toggle)

        // Aplica modificadores
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            finalView = modifierRegistry.apply(modifiers, to: finalView, context: context)
        }
        
        // Aplicar modificadores de ação diretamente do node
        finalView = applyActionModifiers(node: node, context: context, to: finalView)
        
        return finalView
    }

    // Método para registrar o componente
    public static func register() {
        // Registra o componente principal
        DSLComponentRegistry.shared.register("toggle", builder: render)

        // Registra modificadores de base comuns
        registerBaseViewModifiers(on: modifierRegistry)

        // Registra modificadores específicos do Toggle
        modifierRegistry.register("disabled") { view, value, context in
            let isDisabled = DSLExpression.shared.evaluate(value, context) as? Bool ?? false
            return AnyView(view.disabled(isDisabled))
        }

        // Modificador `foreground` movido para registerBaseViewModifiers
        /*
        modifierRegistry.register("foreground") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let color = parseColor(evaluatedValue) {
                 if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                     return AnyView(view.foregroundStyle(color))
                 } else {
                     return AnyView(view.foregroundColor(color))
                 }
            }
            return view
        }
        */

        modifierRegistry.register("tint") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let color = parseColor(evaluatedValue) {
                return AnyView(view.tint(color))
            }
            return view
        }
        
        modifierRegistry.register("labelsHidden") { view, value, context in
            let hidden = DSLExpression.shared.evaluate(value, context) as? Bool ?? true // Default true
            if hidden {
                return AnyView(view.labelsHidden())
            }
            return view
        }
        
        // Outros modificadores específicos de Toggle poderiam ser adicionados aqui
        // ex: toggleStyle, etc.
    }
} 
