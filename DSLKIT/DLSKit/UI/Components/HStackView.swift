import SwiftUI

public struct HStackView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        let rawAlign = node["alignment"]
        let alignStr = DSLExpression.shared.evaluate(rawAlign, context) as? String
        let vAlignment: VerticalAlignment = {
            switch alignStr?.lowercased() {
            case "bottom":   return .bottom
            case "center":   return .center
            case "firstTextBaseline":   return .firstTextBaseline
            case "lastTextBaseline":   return .lastTextBaseline
            case "top":   return .top
            default:         return .top
            }
        }()
        let rawSpacing = node["spacing"]
        let spacing = DSLExpression.shared.evaluate(rawSpacing, context) as? CGFloat

        let children = node["children"] as? [[String: Any]] ?? []
        var view = AnyView(
            HStack(alignment: vAlignment, spacing: spacing) {
                DSLViewRenderer.renderChildren(from: children, context: context)
            }
        )

        if let modifiers = node["modifiers"] as? [[String: Any]] {
            view = modifierRegistry.apply(modifiers, to: view, context: context)
        }
        return view
    }


    public static func register() {
        DSLComponentRegistry.shared.register("hstack", builder: render)

        // Registra modificadores de base comuns
        registerBaseViewModifiers(on: modifierRegistry)

        // Modificadores específicos de HStack
        // 'alignment' e 'spacing' são tratados no render() para HStack

        // Modificadores de Eventos (mantidos aqui por enquanto)
        modifierRegistry.register("onTapGesture") { view, paramsAny, context in
             let params = paramsAny // Ação/evento
             return AnyView(view.onTapGesture {
                 DSLInterpreter.shared.handleEvent(params, context: context)
             })
         }
         modifierRegistry.register("onAppear") { view, paramsAny, context in
             // Ação/evento
             return AnyView(view.onAppear {
                 DSLInterpreter.shared.handleEvent(paramsAny, context: context)
             })
         }
         modifierRegistry.register("onDisappear") { view, paramsAny, context in
             // Ação/evento
             return AnyView(view.onDisappear {
                 DSLInterpreter.shared.handleEvent(paramsAny, context: context)
             })
         }

        // Modificador de Acessibilidade (mantido aqui)
        modifierRegistry.register("accessibilityLabel") { view, paramsAny, context in
            let labelText = DSLExpression.shared.evaluate(paramsAny, context) as? String ?? ""
            if labelText.isEmpty {
                 return AnyView(view.accessibilityLabel(""))
            } else {
                return AnyView(view.accessibilityLabel(Text(labelText)))
            }
        }
        
        // Modificador de Prioridade de Layout (mantido aqui)
        modifierRegistry.register("layoutPriority") { view, paramsAny, context in
            let priority = DSLExpression.shared.evaluate(paramsAny, context) as? Double ?? 0
            return AnyView(view.layoutPriority(priority))
        }
        
        // TODO: Revisar 'mask' - implementação atual é placeholder
        // modifierRegistry.register("mask") { view, paramsAny, context in
        //     return AnyView(view.mask(EmptyView())) 
        // }
    }
}
