import SwiftUI
import Foundation

public struct ImageView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // --- Modificadores e Parâmetros Comuns ---
        let modifiers = node["modifiers"] as? [[String: Any]] ?? []
        let frameModifier = modifiers.first(where: { $0["frame"] != nil })
        let params = frameModifier?["frame"] as? [String: Any] ?? [:]

        let minWidth = parseDimension("minWidth", frameParams: params, evaluated: DSLExpression.shared.evaluate(params["minWidth"], context) as Any)
        let idealWidth = parseDimension("width", frameParams: params, evaluated: DSLExpression.shared.evaluate(params["width"], context) as Any)
        let maxWidth = parseDimension("maxWidth", frameParams: params, evaluated: DSLExpression.shared.evaluate(params["maxWidth"], context) as Any)
        let minHeight = parseDimension("minHeight", frameParams: params, evaluated: DSLExpression.shared.evaluate(params["minHeight"], context) as Any)
        let idealHeight = parseDimension("height", frameParams: params, evaluated: DSLExpression.shared.evaluate(params["height"], context) as Any)
        let maxHeight = parseDimension("maxHeight", frameParams: params, evaluated: DSLExpression.shared.evaluate(params["maxHeight"], context) as Any)
        let alignmentString = DSLExpression.shared.evaluate(params["alignment"], context) as? String
        let alignment: Alignment = mapAlignment(from: alignmentString)

        // --- Placeholder Info (apenas para URL) ---
        let placeholderModifier = modifiers.first(where: { $0["placeholder"] != nil })
        let placeholderDict = placeholderModifier?["placeholder"] as? [String: Any]
        let backgroundValueRaw = placeholderDict?["background"]
        let hasBackground = DSLExpression.shared.evaluate(backgroundValueRaw, context)

        // --- Imagem Base (System ou URL) ---
        var baseView: AnyView?

        // 1. Tenta carregar System Image
        if let systemNameExpr = node["systemName"],
           let systemName = DSLExpression.shared.evaluate(systemNameExpr, context) as? String,
           !systemName.isEmpty {
            
            // Cria a Image diretamente com systemName
            let systemImage = Image(systemName: systemName)
                .conditionalResizableScaled( // Aplica resizable/scaling se necessário
                    modifiers,
                    minWidth: minWidth,
                    idealWidth: idealWidth,
                    maxWidth: maxWidth,
                    minHeight: minHeight,
                    idealHeight: idealHeight,
                    maxHeight: maxHeight,
                    alignment: alignment
                )
            baseView = AnyView(systemImage)

        // 2. Se não for system image, tenta carregar URL
        } else if let urlExpr = node["url"],
                  let urlString = DSLExpression.shared.evaluate(urlExpr, context) as? String,
                  let url = URL(string: urlString) {
            
            let shouldCache = DSLExpression.shared.evaluate(node["cache"], context) as? Bool ?? true

            // Tenta carregar do cache local primeiro
            if shouldCache, let cachedImage = ImageFileCache.shared.load(for: url) {
                let cachedImageView = Image(uiImage: cachedImage)
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
                baseView = AnyView(cachedImageView) // REMOVIDO .cornerRadius() daqui
            } else {
                // Usa AsyncImage se não estiver no cache ou cache desabilitado
                baseView = AnyView(AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        if hasBackground != nil {
                            Rectangle()
                                .fill(parseColor(hasBackground) ?? Color.gray.opacity(0.3))
                                .frame(width: idealWidth ?? 50, height: idealHeight ?? 50)
                                // .cornerRadius removido daqui também, será aplicado por modificador
                        } else {
                            ProgressView()
                                .frame(width: idealWidth ?? 50, height: idealHeight ?? 50)
                        }
                    case .success(let image):
                        image // A imagem carregada
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
                            // .cornerRadius removido daqui
                            .task {
                                if shouldCache {
                                    await MainActor.run {
                                        let renderer = ImageRenderer(content: image)
                                        if let uiImage = renderer.uiImage {
                                            ImageFileCache.shared.save(uiImage, for: url)
                                        }
                                    }
                                }
                            }
                    case .failure:
                        Text("Error loading image") // TODO: Melhorar visual de erro
                    @unknown default:
                        EmptyView()
                    }
                })
            }
        }

        // --- Aplicação Final dos Modificadores ---
        guard var finalView = baseView else {
            // Retorna EmptyView se nem systemName nem url válidos foram fornecidos
            return AnyView(EmptyView())
        }

        // Aplicar outros modificadores genéricos (incluindo cornerRadius agora)
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            finalView = modifierRegistry.apply(modifiers, to: finalView, context: context)
        }

        // Aplicar modificadores de ação diretamente do node
        finalView = applyActionModifiers(node: node, context: context, to: finalView)

        return finalView
    }

    public static func register() {
        DSLComponentRegistry.shared.register("image", builder: render)

        // Registra modificadores de base comuns (incluindo cornerRadius)
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
              // Este modificador agora é tratado por conditionalResizableScaled
              // Pode ser removido ou deixado como redundante (seguro)
              // return AnyView(view.scaledToFill())
             print("INFO: scaledToFill modifier applied via conditionalResizableScaled based on presence.")
             return view // Retorna a view inalterada pois já foi tratado
          }

          modifierRegistry.register("scaledToFit") { view, _, _ in
               // Este modificador agora é tratado por conditionalResizableScaled
               // return AnyView(view.scaledToFit())
               print("INFO: scaledToFit modifier applied via conditionalResizableScaled based on presence.")
              return view // Retorna a view inalterada pois já foi tratado
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

         // --- Modificadores de Eventos (Podem ser úteis em Imagens) ---
         modifierRegistry.register("onTapGesture") { view, paramsAny, context in
              return view
          }
         
         // Nota: Outros modificadores base como frame, padding, background, opacity, etc.
         // são cobertos por registerBaseViewModifiers
    }
}
