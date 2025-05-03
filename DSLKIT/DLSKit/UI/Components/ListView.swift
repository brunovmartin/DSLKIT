import SwiftUI

public struct ListView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    // ADD BACK IndexedItem struct
    private struct IndexedItem: Identifiable {
        let id = UUID() // Use UUID for unique ID if data has no inherent ID
        let index: Int
        let originalValue: Any // Keep the original value if needed, though maybe not directly used here
    }
    
    // REMOVE Row Wrapper View
    /*
    private struct ListRowWrapper: View { ... }
    */

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // 1) Extract data source expression
        guard let dataExpr = node["data"] else { // Get the expression itself
            return AnyView(Text("List Error: Missing 'data' source definition"))
        }

        // 2) Extract row template
        guard let rowContentTemplate = node["children"] as? [String: Any] else {
            return AnyView(Text("List Error: Missing 'children' template"))
        }
        
        // REMOVE Separator Config Extraction 
        /*
        var separatorVisible: Bool = true // Default
        var separatorColor: Color? = nil
        let allModifiers = node["modifiers"] as? [[String: Any]] ?? [] // Get all modifiers
        // ... (extraction logic removed) ...
        */

        // 3) Evaluate the data source expression to get the array
        let resolvedData = DSLExpression.shared.evaluate(dataExpr, context)
        let itemsArray = resolvedData as? [Any] ?? []

        // Create Identifiable items for ForEach
        let indexedItems: [IndexedItem] = itemsArray.enumerated().map { index, element in
            IndexedItem(index: index, originalValue: element) // Use the Identifiable initializer
        }

        // 4) Build the List using ForEach with Identifiable items
        let list = List {
            ForEach(indexedItems) { itemWrapper in
                // Create a context specific to this item's index
                let itemContext = context.contextForIndex(itemWrapper.index) // Cria contexto filho

                // Render the component using the item-specific context
                // A avaliação da expressão dentro de renderComponent agora usará itemContext
                return DSLViewRenderer.renderComponent(from: rowContentTemplate, context: itemContext) // Passa itemContext
                    .id(itemWrapper.id) // Use the stable ID from the wrapper
            }
        }

        // Wrap the List in AnyView for type erasure
        var contentView = AnyView(list)

        // 5) Apply modifiers (like listStyle, frame, etc.) TO THE LIST VIEW
        // No filtering needed here, apply all modifiers defined on the list node.
        if let modifiers = node["modifiers"] as? [[String: Any]] { 
            contentView = modifierRegistry.apply(modifiers, to: contentView, context: context)
        }
        
        contentView = applyActionModifiers(node: node, context: context, to: contentView)

        return contentView
    }

    // --- register function --- 
    public static func register() {
        DSLComponentRegistry.shared.register("list", builder: render)
        
        // Base modifiers are registered elsewhere
        // registerBaseViewModifiers(on: modifierRegistry)
        
        // --- Modifiers Específicos de List (Applied to the List itself) ---
        modifierRegistry.register("listStyle") { view, paramsAny, context in
            let evaluatedStyle = DSLExpression.shared.evaluate(paramsAny, context) as? String

            switch evaluatedStyle?.lowercased() {
            case "plain":
                return AnyView(view.listStyle(.plain))
            case "grouped":
                return AnyView(view.listStyle(.grouped))
            case "inset":
                 if #available(iOS 14.0, macOS 11.0, *) {
                     return AnyView(view.listStyle(.inset)) // Disponível em iOS 14+
                 } else {
                     return AnyView(view.listStyle(.grouped)) // Fallback para iOS 13
                 }
            case "insetgrouped":
                 if #available(iOS 14.0, macOS 11.0, *) {
                     return AnyView(view.listStyle(.insetGrouped))
                 } else {
                     return AnyView(view.listStyle(.grouped)) // Fallback para iOS 13
                 }
             case "sidebar":
                  if #available(iOS 14.0, macOS 11.0, *) {
                      return AnyView(view.listStyle(.sidebar))
                  } else {
                      logDebug("⚠️ ListStyle 'sidebar' not available on this OS version.")
                      return view // Ou um fallback como .plain
                  }
            default:
                logDebug("⚠️ ListStyle modifier: Unknown or invalid style '\(evaluatedStyle ?? "nil")'. Applying default.")
                // Default pode ser .automatic ou um estilo seguro como .insetGrouped
                if #available(iOS 14.0, macOS 11.0, *) {
                    return AnyView(view.listStyle(.insetGrouped))
                } else {
                    return AnyView(view.listStyle(.grouped))
                }
            }
        }

        // listRowSeparator is NOT registered here anymore

        modifierRegistry.register("safeAreaInset") { view, paramsAny, context in
            guard let params = paramsAny as? [String: Any],
                  let edgeStr = DSLExpression.shared.evaluate(params["edge"], context) as? String,
                  let contentNode = params["content"] as? [String: Any] else {
                logDebug("⚠️ safeAreaInset modifier: Invalid parameters. Need 'edge' (string) and 'content' (dictionary).")
                return view // Retorna a view original se os params estiverem errados
            }

            // Avalia parâmetros opcionais
            let spacing = castToCGFloat(DSLExpression.shared.evaluate(params["spacing"], context))
            let alignmentStr = DSLExpression.shared.evaluate(params["alignment"], context) as? String

            // Renderiza o conteúdo do inset ANTES de aplicar o modificador
            let insetContent = DSLViewRenderer.renderComponent(from: contentNode, context: context)

            //logDebug("--- DEBUG: Applying safeAreaInset to edge: \(edgeStr)")

            // Chama a assinatura correta baseada na string da borda
            switch edgeStr.lowercased() {
            case "top":
                let align: HorizontalAlignment = mapHorizontalAlignment(from: alignmentStr) ?? .center
                return AnyView(view.safeAreaInset(edge: .top, alignment: align, spacing: spacing) { insetContent })
            case "bottom":
                 let align: HorizontalAlignment = mapHorizontalAlignment(from: alignmentStr) ?? .center
                return AnyView(view.safeAreaInset(edge: .bottom, alignment: align, spacing: spacing) { insetContent })
            case "leading":
                 let align: VerticalAlignment = mapVerticalAlignment(from: alignmentStr) ?? .center
                return AnyView(view.safeAreaInset(edge: .leading, alignment: align, spacing: spacing) { insetContent })
            case "trailing":
                 let align: VerticalAlignment = mapVerticalAlignment(from: alignmentStr) ?? .center
                return AnyView(view.safeAreaInset(edge: .trailing, alignment: align, spacing: spacing) { insetContent })
            default:
                logDebug("⚠️ safeAreaInset modifier: Invalid edge '\(edgeStr)'. Modifier not applied.")
                return view // Retorna a view original se a borda for inválida
            }
        } // Fim da closure safeAreaInset
    }
}
