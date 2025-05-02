//
//  ModifierHelpers.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//

import SwiftUI

public func mapEdgeSet(from strings: [String]?) -> Edge.Set {
    guard let strings = strings else { return .all }
    var edgeSet: Edge.Set = []
    for str in strings {
        switch str.lowercased() {
        case "top": edgeSet.insert(.top)
        case "bottom": edgeSet.insert(.bottom)
        case "leading": edgeSet.insert(.leading)
        case "trailing": edgeSet.insert(.trailing)
        case "horizontal": edgeSet.insert(.horizontal)
        case "vertical": edgeSet.insert(.vertical)
        case "all": edgeSet.insert(.all)
        default: break
        }
    }
     return edgeSet
}

public func mapAlignment(from string: String?) -> Alignment {
    guard let string = string?.lowercased() else { return .center }
    switch string {
    case "center": return .center
    case "leading": return .leading
    case "trailing": return .trailing
    case "top": return .top
    case "bottom": return .bottom
    case "topLeading": return .topLeading
    case "topTrailing": return .topTrailing
    case "bottomLeading": return .bottomLeading
    case "bottomTrailing": return .bottomTrailing
    default: return .center
    }
}

public func mapNavDisplayMode(_ mode: String?) -> NavigationBarItem.TitleDisplayMode {
    switch mode?.lowercased() {
    case "inline": return .inline
    case "large": return .large
    default: return .automatic
    }
}

public func mapFontWeight(_ weightName: String?) -> Font.Weight? {
    guard let weightName = weightName?.lowercased() else { return nil }
    switch weightName {
    case "ultralight": return .ultraLight
    case "thin": return .thin
    case "light": return .light
    case "regular": return .regular
    case "medium": return .medium
    case "semibold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    case "black": return .black
    default: return nil
    }
}

func parseDimension(_ key: String, frameParams: [String: Any], evaluated: Any) -> CGFloat? {
    guard frameParams[key] != nil else { return CGFloat(1) }
    if let s = evaluated as? String, s.lowercased() == ".infinity" { return .infinity }
    if let number = evaluated as? NSNumber { return CGFloat(number.doubleValue) }
    if let float = evaluated as? CGFloat { return float }
    return nil
}

public func mapTextStyle(from styleName: String?) -> Font.TextStyle? {
    guard let styleName = styleName?.lowercased() else { return nil }
    switch styleName {
    case "largetitle": return .largeTitle
    case "title": return .title // Mapeia para title1
    case "title2": return .title2
    case "title3": return .title3
    case "headline": return .headline
    case "subheadline": return .subheadline
    case "body": return .body
    case "callout": return .callout
    case "footnote": return .footnote
    case "caption": return .caption // Mapeia para caption1
    case "caption2": return .caption2
    default: return nil
    }
}

@available(iOS 16.1, macOS 13.0, tvOS 16.1, watchOS 9.1, *)
public func mapFontDesign(_ designName: String?) -> Font.Design? {
    guard let designName = designName?.lowercased() else { return nil }
    switch designName {
    case "default": return .default
    case "monospaced": return .monospaced
    case "rounded": return .rounded
    case "serif": return .serif
    default: return nil
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public func mapFontWidth(_ widthName: String?) -> Font.Width? {
    guard let widthName = widthName?.lowercased() else { return nil }
    switch widthName {
    case "compressed": return .compressed
    case "condensed": return .condensed
    case "standard": return .standard
    case "expanded": return .expanded
    default: return nil
    }
}

// Add these functions to ModifierHelpers.swift

public func mapContentMode(from string: String?) -> ContentMode {
    switch string?.lowercased() {
    case "fit": return .fit
    case "fill": return .fill
    default: return .fit // Default to fit
    }
}

public func mapRenderingMode(from string: String?) -> Image.TemplateRenderingMode? {
    switch string?.lowercased() {
    case "template": return .template
    case "original": return .original
    default: return nil // Default behavior (often like .original)
    }
}

public func mapInterpolation(from string: String?) -> Image.Interpolation {
    switch string?.lowercased() {
    case "high": return .high
    case "medium": return .medium
    case "low": return .low
    case "none": return .none
    default: return .high // Default to high quality
    }
}

// MARK: - Base View Modifier Registration Helper

/// Registra um conjunto de modificadores comuns aplicáveis à maioria das Views (layout, estilo base, transformações).
public func registerBaseViewModifiers(on registry: DSLModifierRegistry<AnyView>) {

    // MARK: Padding
    registry.register("padding") { view, paramsAny, context in
        let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)
        if evaluatedParams is NSNull || (evaluatedParams as? [String: Any])?.isEmpty == true || (evaluatedParams as? Bool) == true {
            return AnyView(view.padding())
        } else if let length = castToCGFloat(evaluatedParams) {
            return AnyView(view.padding(length))
        } else if let paramsDict = evaluatedParams as? [String: Any] {
            if let edgesList = paramsDict["edges"] as? [String], let lengthValue = paramsDict["length"] {
                let edges = mapEdgeSet(from: edgesList) // Necessita de mapEdgeSet
                let length = castToCGFloat(DSLExpression.shared.evaluate(lengthValue, context)) ?? 0 // Avalia o valor do comprimento
                return AnyView(view.padding(edges, length))
            } else if paramsDict.keys.contains(where: { ["top", "leading", "bottom", "trailing"].contains($0) }) {
                let top = castToCGFloat(DSLExpression.shared.evaluate(paramsDict["top"], context))
                let leading = castToCGFloat(DSLExpression.shared.evaluate(paramsDict["leading"], context))
                let bottom = castToCGFloat(DSLExpression.shared.evaluate(paramsDict["bottom"], context))
                let trailing = castToCGFloat(DSLExpression.shared.evaluate(paramsDict["trailing"], context))
                let insets = EdgeInsets(top: top ?? 0, leading: leading ?? 0, bottom: bottom ?? 0, trailing: trailing ?? 0)
                return AnyView(view.padding(insets))
            } else {
                return AnyView(view.padding()) // Fallback para dicionário não reconhecido
            }
        } else {
            return AnyView(view.padding()) // Fallback para outros tipos
        }
    }

    // MARK: Frame
    registerFrameViewModifiers(on: registry)

    // MARK: Background
    registry.register("background") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        if let color = parseColor(evaluatedValue) { // Necessita de parseColor
            return AnyView(view.background(color))
        }
        // Nota: Background pode aceitar outras Views/Shapes. Simplificado para Color por enquanto.
        return view
    }

    // MARK: Opacity
    registry.register("opacity") { view, value, context in
        let raw = DSLExpression.shared.evaluate(value, context)
        let opacityValue = raw as? Double ?? 1.0 // Padrão 1.0 se falhar
        // Garante que o valor esteja entre 0.0 e 1.0
        return AnyView(view.opacity(max(0.0, min(1.0, opacityValue))))
    }

    // MARK: Corner Radius (via clipShape)
    registry.register("cornerRadius") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        // Garante que o raio é um número não negativo
        guard let radius = castToCGFloat(evaluatedValue), radius >= 0 else { return view } // Necessita de castToCGFloat
        // Aplica usando clipShape com RoundedRectangle
        return AnyView(view.clipShape(RoundedRectangle(cornerRadius: radius)))
    }

    // MARK: Clip Shape
    registry.register("clipShape") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        if let shapeName = evaluatedValue as? String {
            // Mapeia nomes de formas comuns
            switch shapeName.lowercased() {
            case "circle": return AnyView(view.clipShape(Circle()))
            case "capsule": return AnyView(view.clipShape(Capsule()))
            case "rectangle": return AnyView(view.clipShape(Rectangle()))
            // case "ellipse": return AnyView(view.clipShape(Ellipse())) // Adicionar se necessário
            default:
                print("⚠️ ClipShape: Forma desconhecida '\(shapeName)'")
                break // Forma não reconhecida
            }
        } else if let shapeDict = evaluatedValue as? [String: Any],
                  let type = shapeDict["type"] as? String, type.lowercased() == "roundedrectangle" {
            // Suporte para RoundedRectangle com cornerRadius especificado
            let cornerRadius = castToCGFloat(DSLExpression.shared.evaluate(shapeDict["cornerRadius"], context)) ?? 0
            return AnyView(view.clipShape(RoundedRectangle(cornerRadius: cornerRadius)))
        }
        return view // Retorna a view original se a forma não for reconhecida
    }

    // MARK: Overlay (Color only)
    registry.register("overlay") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
         if let color = parseColor(evaluatedValue) { // Necessita de parseColor
             // Overlay simples com cor
             return AnyView(view.overlay(color))
         }
        // TODO: Suportar overlay com Shape e stroke? Ex: {"shape": "circle", "stroke": "red", "lineWidth": 2}
        print("⚠️ Overlay: Suportado apenas com valor de cor por enquanto.")
        return view
    }

    // MARK: Border
    registry.register("border") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        if let color = parseColor(evaluatedValue) { // Necessita de parseColor
            // Borda simples com cor e largura padrão 1
            return AnyView(view.border(color, width: 1)) // É preferível usar a API .border quando possível
        } else if let dict = evaluatedValue as? [String: Any] {
            // Borda com cor e largura especificadas
            let color = parseColor(DSLExpression.shared.evaluate(dict["color"], context)) ?? .black
            let width = castToCGFloat(DSLExpression.shared.evaluate(dict["width"], context)) ?? 1
            // .border(ShapeStyle, width:) é mais recente, usar overlay com stroke para compatibilidade ou se preferir
             if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                  // Use a API .border que aceita ShapeStyle diretamente
                 return AnyView(view.border(color, width: width))
             } else {
                  // Fallback usando overlay para versões mais antigas
                 return AnyView(view.overlay(Rectangle().stroke(color, lineWidth: width)))
             }
        }
        return view
    }

    // MARK: Shadow
    registry.register("shadow") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        // Espera um dicionário para os parâmetros da sombra
        guard let dict = evaluatedValue as? [String: Any] else {
            print("⚠️ Shadow: Parâmetro inválido. Esperado um dicionário com color, radius, x, y.")
            return view
        }
        // Cor padrão se não especificada
        let color = parseColor(DSLExpression.shared.evaluate(dict["color"], context)) ?? Color(.sRGBLinear, white: 0, opacity: 0.33)
        let radius = castToCGFloat(DSLExpression.shared.evaluate(dict["radius"], context)) ?? 0
        let x = castToCGFloat(DSLExpression.shared.evaluate(dict["x"], context)) ?? 0
        let y = castToCGFloat(DSLExpression.shared.evaluate(dict["y"], context)) ?? 0
        return AnyView(view.shadow(color: color, radius: radius, x: x, y: y))
    }

    // MARK: Blur
    registry.register("blur") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        // Raio do blur, padrão 0 se inválido
        let radius = castToCGFloat(evaluatedValue) ?? 0
        // Garante que o raio não seja negativo
        return AnyView(view.blur(radius: max(0, radius)))
    }

    // MARK: Offset
    registry.register("offset") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        // Suporte para dicionário {"x": ..., "y": ...}
        if let dict = evaluatedValue as? [String: Any] {
            let x = castToCGFloat(DSLExpression.shared.evaluate(dict["x"], context)) ?? 0
            let y = castToCGFloat(DSLExpression.shared.evaluate(dict["y"], context)) ?? 0
            return AnyView(view.offset(x: x, y: y))
        // Suporte para array [x, y]
        } else if let sizeArray = evaluatedValue as? [Double], sizeArray.count == 2 {
             return AnyView(view.offset(x: CGFloat(sizeArray[0]), y: CGFloat(sizeArray[1])))
        }
        print("⚠️ Offset: Parâmetro inválido. Esperado dicionário {x, y} ou array [x, y].")
        return view
    }

    // MARK: Scale Effect
    registry.register("scaleEffect") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        // Suporte para escala uniforme (número)
        if let scale = castToCGFloat(evaluatedValue) {
            return AnyView(view.scaleEffect(scale))
        // Suporte para escala não uniforme {"x": ..., "y": ...}
        } else if let dict = evaluatedValue as? [String: Any] {
            let x = castToCGFloat(DSLExpression.shared.evaluate(dict["x"], context)) ?? 1.0
            let y = castToCGFloat(DSLExpression.shared.evaluate(dict["y"], context)) ?? 1.0
            // TODO: Considerar "anchor" point?
            return AnyView(view.scaleEffect(CGSize(width: x, height: y)))
        }
        print("⚠️ ScaleEffect: Parâmetro inválido. Esperado número ou dicionário {x, y}.")
        return view
    }

    // MARK: Rotation Effect
    registry.register("rotationEffect") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        // Suporte para ângulo em graus (número)
        if let angleDegrees = evaluatedValue as? Double {
             // TODO: Considerar "anchor" point?
            return AnyView(view.rotationEffect(.degrees(angleDegrees)))
        // Suporte para dicionário {"degrees": ...}
        } else if let dict = evaluatedValue as? [String: Any] {
             let angleDegrees = (DSLExpression.shared.evaluate(dict["degrees"], context) as? Double) ?? 0.0
             // TODO: Considerar "anchor" point dict["anchor"]?
             return AnyView(view.rotationEffect(.degrees(angleDegrees)))
        }
        print("⚠️ RotationEffect: Parâmetro inválido. Esperado número (graus) ou dicionário {degrees}.")
        return view
    }

    // MARK: Fixed Size
    registry.register("fixedSize") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        // Suporte para dicionário {"horizontal": bool, "vertical": bool}
        if let dict = evaluatedValue as? [String: Any] {
            let horizontal = DSLExpression.shared.evaluate(dict["horizontal"], context) as? Bool ?? true // Padrão true se dict existe
            let vertical = DSLExpression.shared.evaluate(dict["vertical"], context) as? Bool ?? true   // Padrão true se dict existe
             return AnyView(view.fixedSize(horizontal: horizontal, vertical: vertical))
        // Suporte para booleano simples (aplica em ambas as direções se true)
        } else if let enabled = evaluatedValue as? Bool, enabled {
             return AnyView(view.fixedSize())
        }
        // Se for `false` ou outro tipo, não faz nada
        return view
    }

    // MARK: Allows Hit Testing
    registry.register("allowsHitTesting") { view, value, context in
        // Padrão true se o modificador existir
        let enabled = DSLExpression.shared.evaluate(value, context) as? Bool ?? true
        return AnyView(view.allowsHitTesting(enabled))
    }

    // MARK: Ignores Safe Area
    registry.register("ignoresSafeArea") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        // Suporte para booleano simples (ignora todas as bordas)
        if let ignore = evaluatedValue as? Bool, ignore {
             return AnyView(view.ignoresSafeArea())
        // Suporte para array de strings ["top", "bottom", ...]
        } else if let edgesArray = evaluatedValue as? [String] {
            let edgeSet = mapEdgeSet(from: edgesArray) // Necessita de mapEdgeSet
            if !edgeSet.isEmpty {
                // A API SwiftUI requer regiões, padrão .all
                return AnyView(view.ignoresSafeArea(.all, edges: edgeSet))
            }
        }
        // Não faz nada se o valor for false, nulo ou inválido
        return view
    }
    
    // MARK: Foreground (Color)
    // Aplica cor a Text, Image (template), Shapes (se usado com .fill)
    registry.register("foreground") { view, value, context in
        let evaluatedValue = DSLExpression.shared.evaluate(value, context)
        if let color = parseColor(evaluatedValue) {
             // foregroundStyle é mais moderno e funciona em mais tipos (como Shapes)
             if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                 return AnyView(view.foregroundStyle(color))
             } else {
                 // Fallback para versões mais antigas
                 return AnyView(view.foregroundColor(color))
             }
        }
        return view
    }

    // MARK: Environment
    registry.register("environment") { view, value, context in
        guard let dict = value as? [String: Any], dict.count == 1, let keyPathStr = dict.keys.first else {
            print("⚠️ Environment modifier: Invalid parameters. Expected { \"keyPath\": value }")
            return view
        }
        let rawValue = dict[keyPathStr]
        let evaluatedValue = DSLExpression.shared.evaluate(rawValue, context)
        
        // Mapeia strings comuns para keyPaths
        switch keyPathStr {
        case "colorScheme":
            if let schemeStr = evaluatedValue as? String {
                let scheme: ColorScheme = schemeStr.lowercased() == "dark" ? .dark : .light
                return AnyView(view.environment(\.colorScheme, scheme))
            } else {
                 print("⚠️ Environment modifier (colorScheme): Invalid value type. Expected String ('light' or 'dark').")
            }
        // Adicionar outros keyPaths comuns conforme necessário (ex: sizeCategory, layoutDirection)
        default:
             print("⚠️ Environment modifier: Unsupported keyPath '\(keyPathStr)'")
        }
        return view
    }
    
    // MARK: listRowSeparator
    registry.register("listRowSeparator") { view, paramsAny, context in
        let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)
        
        var isVisible: Bool = true // Default to visible
        var separatorColor: Color? = nil
        
        // Logic to parse params (Bool, String, Dict)
        if let visibilityBool = evaluatedParams as? Bool {
            isVisible = visibilityBool
        } else if let visibilityString = evaluatedParams as? String {
            if visibilityString.lowercased() == "hidden" { isVisible = false }
        } else if let paramsDict = evaluatedParams as? [String: Any] {
            // Parse visibility from dictionary
            if let visibilityValue = paramsDict["visible"] { 
                let evaluatedVisibility = DSLExpression.shared.evaluate(visibilityValue, context)
                if let visibilityBool = evaluatedVisibility as? Bool {
                    isVisible = visibilityBool
                } else if let visibilityString = evaluatedVisibility as? String, visibilityString.lowercased() == "hidden" {
                    isVisible = false
                }
                // Default remains true if key exists but value is invalid or 'visible'
            }
            // Parse color from dictionary
            if let colorValue = paramsDict["color"] { 
                separatorColor = parseColor(DSLExpression.shared.evaluate(colorValue, context))
                // If color is set, implicitly make separator visible unless explicitly hidden
                if paramsDict["visible"] == nil { // Only default to visible if visibility wasn't set
                     isVisible = true
                }
            }
        } else if evaluatedParams != nil && !(evaluatedParams is NSNull) {
            print("⚠️ listRowSeparator modifier: Invalid parameter type \(type(of: evaluatedParams)). Expected Bool, String, or Dictionary.")
        }
        
        // Apply modifiers to the view passed in
        var modifiedView = view
        if #available(iOS 15.0, macOS 12.0, *) {
            if !isVisible {
                modifiedView = AnyView(modifiedView.listRowSeparator(.hidden))
            } else if let color = separatorColor {
                modifiedView = AnyView(modifiedView.listRowSeparatorTint(color))
            } // else: default behavior
        }
        
        return modifiedView
    }
}

// --- Fim das Funções Auxiliares ---

// MARK: - Action Modifier Application Helper

/// Aplica modificadores de ação comuns (onTapGesture, onAppear, onDisappear) lendo diretamente do nó JSON.
public func applyActionModifiers(node: [String: Any], context: DSLContext, to view: AnyView) -> AnyView {
    var modifiedView = view

    // onTapGesture
    if let tapAction = node["onTapGesture"] {
        // print("--- DEBUG: Applying onTapGesture from node")
        modifiedView = AnyView(modifiedView.onTapGesture {
            // print("--- DEBUG: Executing onTapGesture action")
            DSLInterpreter.shared.handleEvent(tapAction, context: context)
        })
    }
    
    // onAppear
    if let appearAction = node["onAppear"] {
         // print("--- DEBUG: Applying onAppear from node")
        modifiedView = AnyView(modifiedView.onAppear {
             // print("--- DEBUG: Executing onAppear action")
            DSLInterpreter.shared.handleEvent(appearAction, context: context)
        })
    }
    
    // onDisappear
    if let disappearAction = node["onDisappear"] {
         // print("--- DEBUG: Applying onDisappear from node")
        modifiedView = AnyView(modifiedView.onDisappear {
             // print("--- DEBUG: Executing onDisappear action")
            DSLInterpreter.shared.handleEvent(disappearAction, context: context)
        })
    }
    
    // Adicione outros modificadores de ação aqui se necessário (ex: onChange para componentes genéricos?)

    return modifiedView
}

// Funções adicionadas para mapear alinhamentos específicos
public func mapHorizontalAlignment(from string: String?) -> HorizontalAlignment? {
    guard let string = string?.lowercased() else { return nil }
    switch string {
    case "leading": return .leading
    case "center": return .center
    case "trailing": return .trailing
    default: return nil // Ou .center como padrão?
    }
}

public func mapVerticalAlignment(from string: String?) -> VerticalAlignment? {
    guard let string = string?.lowercased() else { return nil }
    switch string {
    case "top": return .top
    case "center": return .center
    case "bottom": return .bottom
    case "firstTextBaseline": return .firstTextBaseline
    case "lastTextBaseline": return .lastTextBaseline
    default: return nil // Ou .center como padrão?
    }
}
