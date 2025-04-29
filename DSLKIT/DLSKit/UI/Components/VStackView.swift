import SwiftUI

public struct VStackView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        let rawAlign = node["alignment"]
        let alignStr = DSLExpression.shared.evaluate(rawAlign, context) as? String
        let hAlignment: HorizontalAlignment = {
            switch alignStr?.lowercased() {
            case "center":   return .center
            case "trailing": return .trailing
            default:         return .leading
            }
        }()
        let rawSpacing = node["spacing"]
        let spacing = DSLExpression.shared.evaluate(rawSpacing, context) as? CGFloat

        let children = node["children"] as? [[String: Any]] ?? []
        var view = AnyView(
            VStack(alignment: hAlignment, spacing: spacing) {
                DSLViewRenderer.renderChildren(from: children, context: context)
            }
        )

        if let modifiers = node["modifiers"] as? [[String: Any]] {
            view = modifierRegistry.apply(modifiers, to: view, context: context)
        }
        return view
    }


    public static func register() {
        DSLComponentRegistry.shared.register("vstack", builder: render)

        // Registra modificadores de base comuns
        registerBaseViewModifiers(on: modifierRegistry)

        // Modificadores específicos de VStack
        // 'alignment' e 'spacing' são tratados no render() para VStack

        // Modificadores de Eventos (mantidos aqui por enquanto)
        modifierRegistry.register("onTapGesture") { view, paramsAny, context in
             let params = paramsAny // A ação/evento já deve ter sido avaliada se necessário
             return AnyView(view.onTapGesture {
                 DSLInterpreter.shared.handleEvent(params, context: context)
             })
         }
         modifierRegistry.register("onAppear") { view, paramsAny, context in
             // print("--- DEBUG: REGISTERED onAppear closure EXECUTED by apply(). Modifier value: \(String(describing: paramsAny))")
             return AnyView(view.onAppear { 
                 // print("--- DEBUG: SwiftUI .onAppear action EXECUTED.")
                 DSLInterpreter.shared.handleEvent(paramsAny, context: context)
             })
         }
         modifierRegistry.register("onDisappear") { view, paramsAny, context in
             // let params = paramsAny as? [String: Any] ?? [:] // Ação/evento
             return AnyView(view.onDisappear {
                 DSLInterpreter.shared.handleEvent(paramsAny, context: context)
             })
         }

        // Modificador de Acessibilidade (mantido aqui)
        modifierRegistry.register("accessibilityLabel") { view, paramsAny, context in
            // O valor já deve ser a string ou algo que DSLExpression entende
            let labelText = DSLExpression.shared.evaluate(paramsAny, context) as? String ?? ""
            // Permitir label vazia para remover?
            if labelText.isEmpty {
                 return AnyView(view.accessibilityLabel("")) // Ou .accessibilityHidden(true)?
            } else {
                return AnyView(view.accessibilityLabel(Text(labelText))) // Use Text() para garantir
            }
        }
        
        // Modificador de Prioridade de Layout (mantido aqui)
        modifierRegistry.register("layoutPriority") { view, paramsAny, context in
            // O valor já deve ser o número
            let priority = DSLExpression.shared.evaluate(paramsAny, context) as? Double ?? 0
            return AnyView(view.layoutPriority(priority))
        }
        
        // TODO: Revisar 'mask' - implementação atual é placeholder
        // modifierRegistry.register("mask") { view, paramsAny, context in
        //     // Renderizar o conteúdo da máscara via DSL?
        //     return AnyView(view.mask(EmptyView())) 
        // }
    }
}
