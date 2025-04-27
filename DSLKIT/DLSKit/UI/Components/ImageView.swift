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
        

        modifierRegistry.register("aspectRatio") { view, paramsAny, context in
            let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)

            if let contentModeStr = evaluatedParams as? String {
                let contentMode = mapContentMode(from: contentModeStr)
                return AnyView(view.aspectRatio(contentMode: contentMode))
            } else if let paramsDict = evaluatedParams as? [String: Any] {
                let ratio = castToCGFloat(DSLExpression.shared.evaluate(paramsDict["ratio"], context))
                let contentModeStr = DSLExpression.shared.evaluate(paramsDict["contentMode"], context) as? String
                let contentMode = mapContentMode(from: contentModeStr)

                if let ratio = ratio {
                    return AnyView(view.aspectRatio(ratio, contentMode: contentMode))
                } else {
                    return AnyView(view.aspectRatio(contentMode: contentMode))
                }
            }
            return AnyView(view.aspectRatio(contentMode: .fit))
        }


         modifierRegistry.register("scaledToFill") { view, paramsAny, context in
             let apply = DSLExpression.shared.evaluate(paramsAny, context) as? Bool ?? true
             return apply ? AnyView(view.aspectRatio(contentMode: .fill)) : view
         }

        modifierRegistry.register("renderingMode") { view, paramsAny, context in
             let modeString = DSLExpression.shared.evaluate(paramsAny, context) as? String
             if let mode = mapRenderingMode(from: modeString) {
                 if let originalImage = view.asMirrorChild(type: Image.self) {
                     return AnyView(originalImage.renderingMode(mode))
                 }
                 return view
             }
             return view
         }

         modifierRegistry.register("interpolation") { view, paramsAny, context in
             let qualityString = DSLExpression.shared.evaluate(paramsAny, context) as? String
             let quality = mapInterpolation(from: qualityString)

             if let originalImage = view.asMirrorChild(type: Image.self) {
                 return AnyView(originalImage.interpolation(quality))
             }
             return view
         }

         modifierRegistry.register("antialiased") { view, paramsAny, context in
             let enabled = DSLExpression.shared.evaluate(paramsAny, context) as? Bool ?? false
             if let originalImage = view.asMirrorChild(type: Image.self) {
                 return AnyView(originalImage.antialiased(enabled))
             }
             return view
         }

         modifierRegistry.register("foregroundColor") { view, paramsAny, context in
              let colorValue = DSLExpression.shared.evaluate(paramsAny, context)
              if let color = parseColor(colorValue) {
                  return AnyView(view.foregroundColor(color))
              }
              return view
          }

         modifierRegistry.register("frame") { view, paramsAny, context in
             let params = paramsAny as? [String: Any] ?? [:]
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
             return AnyView(view.frame(minWidth: minWidth, idealWidth: idealWidth, maxWidth: maxWidth, minHeight: minHeight, idealHeight: idealHeight, maxHeight: maxHeight, alignment: alignment))
         }

         modifierRegistry.register("clipShape") { view, paramsAny, context in
              let shapeName = DSLExpression.shared.evaluate(paramsAny, context) as? String
              if shapeName?.lowercased() == "circle" {
                   return AnyView(view.clipShape(Circle()))
              }
              return view
          }

         modifierRegistry.register("cornerRadius") { view, paramsAny, context in
              let radius = DSLExpression.shared.evaluate(paramsAny, context) as? CGFloat ?? 0
              return AnyView(view.clipShape(RoundedRectangle(cornerRadius: radius)))
         }

          modifierRegistry.register("opacity") { view, paramsAny, context in
              let raw = DSLExpression.shared.evaluate(paramsAny, context)
              let value = max(0.0, min(1.0, raw as? Double ?? 1.0))
              return AnyView(view.opacity(value))
          }

          modifierRegistry.register("shadow") { view, paramsAny, context in
              let params = paramsAny as? [String: Any] ?? [:]
              let radius = DSLExpression.shared.evaluate(params["radius"], context) as? CGFloat ?? 0
              let x = DSLExpression.shared.evaluate(params["x"], context) as? CGFloat ?? 0
              let y = DSLExpression.shared.evaluate(params["y"], context) as? CGFloat ?? 0
              return AnyView(view.shadow(radius: radius, x: x, y: y))
          }

         modifierRegistry.register("onTapGesture") { view, paramsAny, context in
              let params = paramsAny as? [String: Any] ?? [:]
              return AnyView(view.onTapGesture {
                  DSLInterpreter.shared.handleEvent(params, context: context)
              })
          }

         modifierRegistry.register("padding") { view, paramsAny, context in
            let evaluatedParams = DSLExpression.shared.evaluate(paramsAny, context)

            if evaluatedParams is NSNull || (evaluatedParams as? [String: Any])?.isEmpty == true || (evaluatedParams as? Bool) == true {
                return AnyView(view.padding())
            }
            else if let length = castToCGFloat(evaluatedParams) {
                return AnyView(view.padding(length))
            }
            else if let paramsDict = evaluatedParams as? [String: Any] {
                if let edgesList = paramsDict["edges"] as? [String], let lengthValue = paramsDict["length"] {
                    let edges = mapEdgeSet(from: edgesList)
                    let length = castToCGFloat(lengthValue) ?? 0
                    return AnyView(view.padding(edges, length))
                }
                else if paramsDict.keys.contains(where: { ["top", "leading", "bottom", "trailing"].contains($0) }) {
                    let top = castToCGFloat(paramsDict["top"])
                    let leading = castToCGFloat(paramsDict["leading"])
                    let bottom = castToCGFloat(paramsDict["bottom"])
                    let trailing = castToCGFloat(paramsDict["trailing"])
                    let insets = EdgeInsets(top: top ?? 0, leading: leading ?? 0, bottom: bottom ?? 0, trailing: trailing ?? 0)
                    return AnyView(view.padding(insets))
                }
                else {
                    return AnyView(view.padding())
                }
            }
            return AnyView(view.padding())
        }

        modifierRegistry.register("background") { view, paramsAny, context in
            let colorValue = DSLExpression.shared.evaluate(paramsAny, context)
             if let color = parseColor(colorValue) {
                 return AnyView(view.background(color))
             } else if let colorHex = colorValue as? String, let color = Color(hex: colorHex) {
                return AnyView(view.background(color))
             }
            return view
        }
    }
}
