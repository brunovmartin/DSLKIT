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
        
        // --- Adicionando mais modificadores --- 

        modifierRegistry.register("background") { view, value, context in
            // Lógica de ButtonView/TextView
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let color = parseColor(evaluatedValue) {
                return AnyView(view.background(color))
            }
            // TODO: Considerar background com ShapeStyle ou View?
            return view
        }

        modifierRegistry.register("foreground") { view, value, context in
            // Lógica de ButtonView/TextView
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let color = parseColor(evaluatedValue) {
                return AnyView(view.foregroundColor(color))
            }
            return view
        }

        modifierRegistry.register("tint") { view, value, context in
            // Modificador tint para cor de acentuação
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let color = parseColor(evaluatedValue) {
                return AnyView(view.tint(color))
            }
            return view
        }

        modifierRegistry.register("scaleEffect") { view, value, context in
            // Permite escalar a view
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let scale = castToCGFloat(evaluatedValue) {
                return AnyView(view.scaleEffect(scale))
            } else if let dict = evaluatedValue as? [String: Any] {
                let x = castToCGFloat(DSLExpression.shared.evaluate(dict["x"], context)) ?? 1.0
                let y = castToCGFloat(DSLExpression.shared.evaluate(dict["y"], context)) ?? 1.0
                // TODO: Anchor point?
                return AnyView(view.scaleEffect(CGSize(width: x, height: y)))
            }
            return view
        }

        modifierRegistry.register("rotationEffect") { view, value, context in
            // Permite rotacionar a view
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let angleDegrees = evaluatedValue as? Double {
                // TODO: Anchor point?
                return AnyView(view.rotationEffect(.degrees(angleDegrees)))
            } else if let dict = evaluatedValue as? [String: Any] {
                 let angleDegrees = (DSLExpression.shared.evaluate(dict["degrees"], context) as? Double) ?? 0.0
                 // TODO: Anchor point dict["anchor"]?
                 return AnyView(view.rotationEffect(.degrees(angleDegrees)))
            }
            return view
        }

        modifierRegistry.register("offset") { view, value, context in
            // Permite deslocar a view
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let dict = evaluatedValue as? [String: Any] {
                let x = castToCGFloat(DSLExpression.shared.evaluate(dict["x"], context)) ?? 0
                let y = castToCGFloat(DSLExpression.shared.evaluate(dict["y"], context)) ?? 0
                return AnyView(view.offset(x: x, y: y))
            } else if let sizeArray = evaluatedValue as? [Double], sizeArray.count == 2 { // [x, y]
                 return AnyView(view.offset(x: CGFloat(sizeArray[0]), y: CGFloat(sizeArray[1])))
            }
            return view
        }
        
        // --- Implementando mais modificadores ---

        modifierRegistry.register("cornerRadius") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            guard let radius = castToCGFloat(evaluatedValue) else { return view }
            // Note: cornerRadius geralmente é usado com clipShape ou background
            // Aplicar diretamente pode não ter o efeito visual esperado sem um background.
            // Uma abordagem comum é aplicar clipShape(RoundedRectangle(cornerRadius: radius))
            // Por simplicidade, aplicamos clipShape aqui.
            return AnyView(view.clipShape(RoundedRectangle(cornerRadius: radius)))
        }

        modifierRegistry.register("clipShape") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let shapeName = evaluatedValue as? String {
                 // Mapeia o nome da forma para a Shape real (requer função helper)
                switch shapeName.lowercased() {
                case "circle":
                    return AnyView(view.clipShape(Circle()))
                case "capsule":
                    return AnyView(view.clipShape(Capsule()))
                case "rectangle":
                     return AnyView(view.clipShape(Rectangle()))
                 // Outros casos podem ser adicionados (ex: Ellipse)
                default:
                     break // Forma não reconhecida
                }
            } else if let shapeDict = evaluatedValue as? [String: Any], 
                      let type = shapeDict["type"] as? String, type.lowercased() == "roundedrectangle" {
                 let cornerRadius = castToCGFloat(DSLExpression.shared.evaluate(shapeDict["cornerRadius"], context)) ?? 0
                 // TODO: Suportar style (continuous/circular)?
                 return AnyView(view.clipShape(RoundedRectangle(cornerRadius: cornerRadius)))
            }
            return view
        }

        // Nota: Overlay com View arbitrária é complexo. Implementando com Color/ShapeStyle por enquanto.
        modifierRegistry.register("overlay") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
             if let color = parseColor(evaluatedValue) {
                 // Overlay simples com cor
                 return AnyView(view.overlay(color))
             }
            // TODO: Suportar overlay com Shape e stroke? Ex: {"shape": "circle", "stroke": "red", "lineWidth": 2}
            return view
        }

        modifierRegistry.register("border") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let color = parseColor(evaluatedValue) {
                // Borda simples com cor e largura padrão
                return AnyView(view.border(color))
            } else if let dict = evaluatedValue as? [String: Any] {
                let color = parseColor(DSLExpression.shared.evaluate(dict["color"], context)) ?? .black
                let width = castToCGFloat(DSLExpression.shared.evaluate(dict["width"], context)) ?? 1
                // Nota: view.border(color, width: width) pode precisar de clipShape antes.
                // Uma alternativa é usar overlay(Rectangle().stroke(color, lineWidth: width))
                return AnyView(view.overlay(Rectangle().stroke(color, lineWidth: width)))
            }
            return view
        }
        
        modifierRegistry.register("shadow") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
             guard let dict = evaluatedValue as? [String: Any] else { return view }

            let color = parseColor(DSLExpression.shared.evaluate(dict["color"], context)) ?? Color(.sRGBLinear, white: 0, opacity: 0.33)
            let radius = castToCGFloat(DSLExpression.shared.evaluate(dict["radius"], context)) ?? 0
            let x = castToCGFloat(DSLExpression.shared.evaluate(dict["x"], context)) ?? 0
            let y = castToCGFloat(DSLExpression.shared.evaluate(dict["y"], context)) ?? 0
            
            return AnyView(view.shadow(color: color, radius: radius, x: x, y: y))
        }

        modifierRegistry.register("blur") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            let radius = castToCGFloat(evaluatedValue) ?? 0
            return AnyView(view.blur(radius: radius))
        }

        modifierRegistry.register("fixedSize") { view, value, context in
            let evaluatedValue = DSLExpression.shared.evaluate(value, context)
            if let dict = evaluatedValue as? [String: Any] {
                let horizontal = DSLExpression.shared.evaluate(dict["horizontal"], context) as? Bool ?? true // Default to true if dict exists
                let vertical = DSLExpression.shared.evaluate(dict["vertical"], context) as? Bool ?? true   // Default to true if dict exists
                 return AnyView(view.fixedSize(horizontal: horizontal, vertical: vertical))
            } else if let enabled = evaluatedValue as? Bool, enabled {
                 // Se for apenas `true`, aplica em ambas as direções
                 return AnyView(view.fixedSize())
            } // Se for `false` ou outro tipo, não faz nada
            return view
        }
        
        modifierRegistry.register("allowsHitTesting") { view, value, context in
            let enabled = DSLExpression.shared.evaluate(value, context) as? Bool ?? true // Default to true
            return AnyView(view.allowsHitTesting(enabled))
        }
        
        modifierRegistry.register("labelsHidden") { view, value, context in
            let hidden = DSLExpression.shared.evaluate(value, context) as? Bool ?? true // Default to true if modifier exists
            if hidden {
                return AnyView(view.labelsHidden())
            }
            return view
        }
    }
} 
