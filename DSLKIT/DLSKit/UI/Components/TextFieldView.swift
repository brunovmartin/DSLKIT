//
//  TextFieldView.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import SwiftUI

public struct TextFieldView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        let placeholder = DSLExpression.shared.evaluate(node["placeholder"], context) as? String ?? ""
        guard let valueExpr = node["value"],
              let valueDict = valueExpr as? [String: Any],
              let varName = valueDict["var"] as? String else {
            print("⚠️ TextFieldView: Definição de 'value' inválida ou faltando. Precisa ser {\"var\": \"nomeVar\"}")
            return AnyView(Text("TextField Error"))
        }

        let textBinding: Binding<String> = BindingResolver.bind(varName, context: context, defaultValue: "")

        print("--- DEBUG: TextFieldView render - varName: \(varName), current value: \(textBinding.wrappedValue)")

        let textField = TextField(placeholder, text: textBinding)
            .onSubmit {
                print("TextField onSubmit for \(varName)")
            }

        var finalView = AnyView(textField)

        // Aplicar modificadores visuais
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            finalView = modifierRegistry.apply(modifiers, to: finalView, context: context)
        }

        // Aplicar modificadores de ação diretamente do node
        finalView = applyActionModifiers(node: node, context: context, to: finalView)

        return finalView
    }

    public static func register() {
        DSLComponentRegistry.shared.register("textfield", builder: render)
        
        // Registra modificadores de base comuns (padding, frame, background, etc.)
        registerBaseViewModifiers(on: modifierRegistry)
        
        // Adicionar modificadores específicos de TextField aqui, se necessário
        // Ex: keyboardType, autocapitalization, disableAutocorrection, submitLabel, etc.
        // Exemplo:
        // modifierRegistry.register("keyboardType") { view, value, context in
        //     let typeName = DSLExpression.shared.evaluate(value, context) as? String
        //     let type = mapKeyboardType(typeName) // Precisa criar mapKeyboardType
        //     return AnyView(view.keyboardType(type))
        // }
    }
}
