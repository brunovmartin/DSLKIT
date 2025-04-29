import SwiftUI
import Foundation

public struct ImageView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        if let urlExpr = node["url"],
           let urlString = DSLExpression.shared.evaluate(urlExpr, context) as? String,
           let url = URL(string: urlString) {
            
            let modifiers = node["modifiers"] as? [[String: Any]] ?? []
            
            let frameModifier = modifiers.first(where: { $0["frame"] != nil })
            let params = frameModifier?["frame"] as? [String: Any] ?? [:]
            
            let minWidth = parseDimension("minWidth", frameParams: params,
                                          evaluated: DSLExpression.shared.evaluate(params["minWidth"], context) as Any)
            let idealWidth = parseDimension("width", frameParams: params,
                                            evaluated: DSLExpression.shared.evaluate(params["width"], context) as Any)
            let maxWidth = parseDimension("maxWidth", frameParams: params,
                                          evaluated: DSLExpression.shared.evaluate(params["maxWidth"], context) as Any)
            let minHeight = parseDimension("minHeight", frameParams: params,
                                           evaluated: DSLExpression.shared.evaluate(params["minHeight"], context) as Any)
            let idealHeight = parseDimension("height", frameParams: params,
                                             evaluated: DSLExpression.shared.evaluate(params["height"], context) as Any)
            let maxHeight = parseDimension("maxHeight", frameParams: params,
                                           evaluated: DSLExpression.shared.evaluate(params["maxHeight"], context) as Any)
            
            let alignmentString = DSLExpression.shared.evaluate(params["alignment"], context) as? String
            let alignment: Alignment = mapAlignment(from: alignmentString)
            
            // Captura o cornerRadius do modificador
            let cornerModifier = modifiers.first(where: { $0["cornerRadius"] != nil })
            let cornerValueRaw = cornerModifier?["cornerRadius"]
            let cornerRadius = DSLExpression.shared.evaluate(cornerValueRaw, context) as? CGFloat ?? 0
            
            let placeholderModifier = modifiers.first(where: { $0["placeholder"] != nil })
            let placeholderDict = placeholderModifier?["placeholder"] as? [String: Any]
            let backgroundValueRaw = placeholderDict?["background"]
            let hasBackground = DSLExpression.shared.evaluate(backgroundValueRaw, context)
            
            if let color = parseColor(hasBackground) {
                let view = AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(color)
                            .frame(width: idealWidth,height: idealHeight)
                            .cornerRadius(cornerRadius)
                        
                    case .success(let image):
                        image
                            .conditionalResizableScaled(
                                modifiers,
                                minWidth: minWidth,
                                idealWidth: idealWidth,
                                maxWidth: maxWidth,
                                minHeight: minHeight,
                                idealHeight: idealHeight,
                                maxHeight: maxHeight,
                                alignment: alignment
                            )
                            .cornerRadius(cornerRadius)
                        
                    case .failure(_):
                        Rectangle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: idealWidth,height: idealHeight)
                            .cornerRadius(cornerRadius)
                        
                    @unknown default:
                        EmptyView()
                    }
                }
                
                return AnyView(view)
                
            } else {
                let view = AsyncImage(url: url) { data in
                    data.image?
                        .conditionalResizableScaled(
                            modifiers,
                            minWidth: minWidth,
                            idealWidth: idealWidth,
                            maxWidth: maxWidth,
                            minHeight: minHeight,
                            idealHeight: idealHeight,
                            maxHeight: maxHeight,
                            alignment: alignment
                        )
                        .cornerRadius(cornerRadius)
                }
                return AnyView(view)
            }


            
            
            
        }
        return AnyView(EmptyView())
    }





    public static func register() {
        DSLComponentRegistry.shared.register("image", builder: render)
        
        // Registra modificadores de base comuns
        registerBaseViewModifiers(on: modifierRegistry)
        
        // --- Modificadores Específicos de Image ---

        modifierRegistry.register("aspectRatio") { view, paramsAny, context in
            let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)
            // Case 1: Ratio only (e.g., "aspectRatio": 1.5)
            if let ratio = castToCGFloat(evaluatedParams) {
                return AnyView(view.aspectRatio(ratio, contentMode: .fit)) // Default to fit
            }
            // Case 2: ContentMode only (e.g., "aspectRatio": "fill")
            else if let contentModeStr = evaluatedParams as? String {
                let contentMode = mapContentMode(from: contentModeStr)
                return AnyView(view.aspectRatio(contentMode: contentMode))
            }
            // Case 3: Dictionary { "ratio": 1.5, "contentMode": "fill" } or { "size": [w, h], "contentMode": ... }
            else if let paramsDict = evaluatedParams as? [String: Any] {
                let contentModeStr = DSLExpression.shared.evaluate(paramsDict["contentMode"], context) as? String
                let contentMode = mapContentMode(from: contentModeStr)
                
                if let ratioVal = paramsDict["ratio"], let ratio = castToCGFloat(DSLExpression.shared.evaluate(ratioVal, context)) {
                    return AnyView(view.aspectRatio(ratio, contentMode: contentMode))
                } else if let sizeVal = paramsDict["size"], let sizeArray = DSLExpression.shared.evaluate(sizeVal, context) as? [Double], sizeArray.count == 2 {
                    let size = CGSize(width: CGFloat(sizeArray[0]), height: CGFloat(sizeArray[1]))
                    return AnyView(view.aspectRatio(size, contentMode: contentMode))
                } else {
                    // Fallback if dictionary is invalid but has contentMode
                    return AnyView(view.aspectRatio(contentMode: contentMode))
                }
            }
            // Default fallback
            return AnyView(view.aspectRatio(contentMode: .fit))
        }

         modifierRegistry.register("scaledToFill") { view, _, _ in
             return AnyView(view.scaledToFill()) // SwiftUI convenience
         }
         
         modifierRegistry.register("scaledToFit") { view, _, _ in
              return AnyView(view.scaledToFit()) // SwiftUI convenience
          }

        modifierRegistry.register("renderingMode") { view, paramsAny, context in
             let modeString = DSLExpression.shared.evaluate(paramsAny, context) as? String
             if let mode = mapRenderingMode(from: modeString) {
                 // Attempt to apply to the underlying Image
                 if let originalImage = view.asMirrorChild(type: Image.self) {
                     return AnyView(originalImage.renderingMode(mode))
                 } else {
                      print("⚠️ renderingMode: Could not apply to non-Image view type.")
                 }
             }
             return view
         }

         modifierRegistry.register("interpolation") { view, paramsAny, context in
             let qualityString = DSLExpression.shared.evaluate(paramsAny, context) as? String
             let quality = mapInterpolation(from: qualityString)
             if let originalImage = view.asMirrorChild(type: Image.self) {
                 return AnyView(originalImage.interpolation(quality))
              } else {
                   print("⚠️ interpolation: Could not apply to non-Image view type.")
              }
             return view
         }

         modifierRegistry.register("antialiased") { view, paramsAny, context in
             let enabled = DSLExpression.shared.evaluate(paramsAny, context) as? Bool ?? false // Default false?
             if let originalImage = view.asMirrorChild(type: Image.self) {
                 return AnyView(originalImage.antialiased(enabled))
              } else {
                   print("⚠️ antialiased: Could not apply to non-Image view type.")
              }
             return view
         }

         modifierRegistry.register("foregroundColor") { view, paramsAny, context in
              let colorValue = DSLExpression.shared.evaluate(paramsAny, context)
              if let color = parseColor(colorValue) {
                   if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                       return AnyView(view.foregroundStyle(color))
                   } else {
                       return AnyView(view.foregroundColor(color))
                   }
              }
              return view
          }

         // --- Modificadores de Eventos (Podem ser úteis em Imagens) ---
         modifierRegistry.register("onTapGesture") { view, paramsAny, context in
              // Ação/evento
              return AnyView(view.onTapGesture {
                  DSLInterpreter.shared.handleEvent(paramsAny, context: context)
              })
          }
         
         // Nota: Outros modificadores base como frame, padding, background, opacity, etc.
         // são cobertos por registerBaseViewModifiers
    }
}
