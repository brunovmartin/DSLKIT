//
//  TextFieldView.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import SwiftUI

public struct TextFieldView {

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

        return AnyView(textField)
    }

    public static func register() {
        DSLComponentRegistry.shared.register("textfield", builder: render)
    }
}
