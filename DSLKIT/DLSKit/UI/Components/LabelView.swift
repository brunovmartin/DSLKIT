import SwiftUI

public struct LabelView {
    // Usaremos o registro global de modificadores, assumindo que modificadores
    // comuns como padding, frame, foreground, etc., são suficientes para Label.
    // Se Label precisar de modificadores MUITO específicos, criaríamos um registro local.
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(node: [String: Any], context: DSLContext) -> AnyView {
        // Ler atributos diretamente do nó, como em ButtonView e ImageView
        let titleExpr = node["title"]
        let imageExpr = node["systemImage"]

        let title = DSLExpression.shared.evaluate(titleExpr, context) as? String ?? ""
        let systemImage = DSLExpression.shared.evaluate(imageExpr, context) as? String

        // Construir a Label base
        let label: any View
        if let imageName = systemImage, !imageName.isEmpty {
            label = Label(title, systemImage: imageName)
        } else {
            // Se não houver imagem, usamos Label apenas com o título.
            // Poderíamos usar Text direto, mas Label pode ter semântica diferente.
            label = Label { Text(title) } icon: { EmptyView() } // Label sem ícone explícito
        }
        
        // Inicializa com AnyView da Label base
        var labelView = AnyView(label)

        // Aplicar TODOS os modificadores (incluindo o novo "labelStyle") da chave "modifiers"
        if let modifiers = node["modifiers"] as? [[String: Any]] {
             labelView = modifierRegistry.apply(modifiers, to: labelView, context: context)
        }
        
        labelView = applyActionModifiers(node: node, context: context, to: labelView)

        return labelView
    }

    public static func register() {
        DSLComponentRegistry.shared.register("label", builder: render)
        
        // Registra modificadores de base comuns (padding, frame, background, opacity, cornerRadius)
        registerBaseViewModifiers(on: modifierRegistry)
        
        // --- Registrar "labelStyle" como modificador --- ADICIONADO
        modifierRegistry.register("labelStyle") { view, value, context in
            let styleName = DSLExpression.shared.evaluate(value, context) as? String
            
            // Tentar aplicar o estilo à Label original dentro do AnyView
            // Isso é um pouco complexo devido ao AnyView. Idealmente, os modificadores
            // que alteram o tipo fundamental deveriam ser aplicados antes do AnyView,
            // mas a estrutura atual aplica após. Vamos tentar com o original `label`.
            // Nota: Isso pode não funcionar perfeitamente se outros modificadores
            // já tiverem encapsulado a Label original em outra estrutura.
            // Uma abordagem mais robusta poderia envolver type casting ou repensar a ordem.
            // Por ora, vamos aplicar ao `view` (AnyView) que pode conter a Label.
            // Tentativa de aplicar diretamente na Label contida (pode falhar se view não for Label direto)
            
            var targetView = view // O AnyView atual
            
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                switch styleName?.lowercased() {
                case "icononly":
                    // Aplica ao AnyView, esperando que ele contenha uma Label
                    // ou algo que responda ao modificador labelStyle.
                    targetView = AnyView(view.labelStyle(.iconOnly))
                case "titleonly":
                    targetView = AnyView(view.labelStyle(.titleOnly))
                case "titleandicon":
                    targetView = AnyView(view.labelStyle(.titleAndIcon))
                default:
                    targetView = AnyView(view.labelStyle(.titleAndIcon)) // Default
                }
            }
            return targetView // Retorna o AnyView modificado
        }
        
        // Se precisarmos de .imageScale() futuramente, registraríamos aqui.
    }
} 
