import SwiftUI

public struct ToggleView {
    // 1. Adiciona um Modifier Registry específico para ToggleView
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // Extrai o label (espera uma string por enquanto)
        let labelText = DSLExpression.shared.evaluate(node["label"], context) as? String ?? ""

        // Extrai o nome da variável booleana do parâmetro 'isOn'
        guard let isOnExpr = node["isOn"],
              let isOnDict = isOnExpr as? [String: Any],
              let varName = isOnDict["var"] as? String else {
            print("⚠️ ToggleView: Definição de 'isOn' inválida ou faltando. Precisa ser {\"var\": \"nomeVarBooleana\"}")
            return AnyView(Text("Toggle Error"))
        }

        // Cria o Binding<Bool> usando o BindingResolver genérico
        // Fornece 'false' como valor padrão se a variável não existir
        let isOnBinding: Binding<Bool> = BindingResolver.bind(varName, context: context, defaultValue: false)

        // Pega a ação onChange da DSL, se existir
        let onChangeAction = node["onChange"]

        print("--- DEBUG: ToggleView render - varName: \(varName), current value: \(isOnBinding.wrappedValue)")

        // Cria a Toggle view
        var toggle = Toggle(labelText, isOn: isOnBinding)
            .onChange(of: isOnBinding.wrappedValue) {
                let currentValue = isOnBinding.wrappedValue
                print("--- DEBUG: Toggle \(varName) changed to \(currentValue)")
                if let action = onChangeAction {
                    print("--- DEBUG: Executing onChange action for \(varName)")
                    DSLInterpreter.shared.handleEvent(action, context: context)
                }
            }

        // Cria AnyView a partir do Toggle tipado
        var finalView = AnyView(toggle)

        // 2. Aplica modificadores usando o registry específico
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            finalView = modifierRegistry.apply(modifiers, to: finalView, context: context)
        }

        return finalView
    }

    // Método para registrar o componente
    public static func register() {
        // Registra o componente principal
        DSLComponentRegistry.shared.register("toggle", builder: render)

        // 3. Registra modificadores aplicáveis ao Toggle usando seu próprio registry
        // (Exemplos: padding, frame, opacity - podemos adicionar mais conforme necessário)

        modifierRegistry.register("padding") { view, paramsAny, context in
            let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)
            // Copiado/adaptado de TextView.swift
            if evaluatedParams is NSNull || (evaluatedParams as? [String: Any])?.isEmpty == true || (evaluatedParams as? Bool) == true {
                return AnyView(view.padding())
            } else if let length = castToCGFloat(evaluatedParams) {
                return AnyView(view.padding(length))
            } else if let paramsDict = evaluatedParams as? [String: Any] {
                if let edgesList = paramsDict["edges"] as? [String], let lengthValue = paramsDict["length"] {
                    let edges = mapEdgeSet(from: edgesList)
                    let length = castToCGFloat(lengthValue) ?? 0
                    return AnyView(view.padding(edges, length))
                } else if paramsDict.keys.contains(where: { ["top", "leading", "bottom", "trailing"].contains($0) }) {
                    let top = castToCGFloat(paramsDict["top"])
                    let leading = castToCGFloat(paramsDict["leading"])
                    let bottom = castToCGFloat(paramsDict["bottom"])
                    let trailing = castToCGFloat(paramsDict["trailing"])
                    let insets = EdgeInsets(top: top ?? 0, leading: leading ?? 0, bottom: bottom ?? 0, trailing: trailing ?? 0)
                    return AnyView(view.padding(insets))
                } else {
                    return AnyView(view.padding())
                }
            } else {
                return AnyView(view.padding())
            }
        }
        
        // --- Adicionando outros modificadores --- 

        modifierRegistry.register("frame") { view, paramsAny, context in
            // Lógica copiada/adaptada de ButtonView.swift
            let params = paramsAny as? [String: Any] ?? [:]

            func parseDimension(_ key: String) -> CGFloat? {
                guard let value = params[key] else { return nil }
                let evaluatedValue = DSLExpression.shared.evaluate(value, context)
                if let stringValue = evaluatedValue as? String, stringValue.lowercased() == ".infinity" {
                    return .infinity
                } else if let number = evaluatedValue as? NSNumber {
                    return CGFloat(number.doubleValue)
                } else if let cgFloat = evaluatedValue as? CGFloat {
                     return cgFloat
                }
                return nil
            }

            let minWidth = parseDimension("minWidth")
            let idealWidth = parseDimension("width")
            let maxWidth = parseDimension("maxWidth")
            let minHeight = parseDimension("minHeight")
            let idealHeight = parseDimension("height")
            let maxHeight = parseDimension("maxHeight")

            let alignmentString = DSLExpression.shared.evaluate(params["alignment"], context) as? String
            // Assumindo que mapAlignment existe em um local acessível (ex: ModifierHelpers.swift)
            let alignment: Alignment = mapAlignment(from: alignmentString)

            return AnyView(view.frame(
                minWidth: minWidth,
                idealWidth: idealWidth,
                maxWidth: maxWidth,
                minHeight: minHeight,
                idealHeight: idealHeight,
                maxHeight: maxHeight,
                alignment: alignment
            ))
        }

        modifierRegistry.register("opacity") { view, value, context in
             // Lógica copiada/adaptada de ButtonView.swift
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            guard let opacityValue = evaluatedValue as? Double else { return view }
            return AnyView(view.opacity(max(0.0, min(1.0, opacityValue))))
        }

        modifierRegistry.register("disabled") { view, value, context in
            // Avalia a expressão DSL para obter o valor booleano
            let isDisabled = DSLExpression.shared.evaluate(value, context) as? Bool ?? false
            return AnyView(view.disabled(isDisabled))
        }
        
        // Adicionar outros modificadores comuns aqui, como:
        // modifierRegistry.register("background") { ... }
        // modifierRegistry.register("foreground") { ... }
    }
} 