import SwiftUI

public struct ListView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    // ADD BACK IndexedItem struct
    private struct IndexedItem: Identifiable {
        let id = UUID() // Use UUID for unique ID if data has no inherent ID
        let index: Int
        let originalValue: Any // Keep the original value if needed, though maybe not directly used here
    }
    
    // REMOVE Hashable struct
    /*
    private struct ListItemData: Hashable {
        let index: Int
        // Use a hash representation of the value. Hashing Any is tricky.
        // Using description's hash is a basic approach, might need refinement
        // depending on the complexity and types of data expected.
        let valueHash: Int

        // Implement Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(index)
            hasher.combine(valueHash)
        }

        // Implement Equatable (needed for Hashable)
        static func == (lhs: ListItemData, rhs: ListItemData) -> Bool {
            return lhs.index == rhs.index && lhs.valueHash == rhs.valueHash
        }

        // Failable initializer to create from Any, calculating hash
        init?(index: Int, value: Any) {
            self.index = index
            // Create hash from the value's string description
            self.valueHash = String(describing: value).hashValue
        }
    }
    */

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // 1) Extract data source expression
        guard let dataExpr = node["data"] else { // Get the expression itself
            return AnyView(Text("List Error: Missing 'data' source definition"))
        }
        // Remove logging for dataVarName, as we use the expression directly
        // print("--- DEBUG: ListView.render - Attempting to read data using expression: \(dataExpr)")

        // 2) Extract row template
        guard let rowContentTemplate = node["children"] as? [String: Any] else {
            return AnyView(Text("List Error: Missing 'children' template"))
        }

        // 3) Evaluate the data source expression to get the array
        let resolvedData = DSLExpression.shared.evaluate(dataExpr, context)
        let itemsArray = resolvedData as? [Any] ?? []
        // Remove extra logging
        // print("--- DEBUG: ListView.render - Read itemsArray (count: \(itemsArray.count)): \(itemsArray)")

        // Create Identifiable items for ForEach
        let indexedItems: [IndexedItem] = itemsArray.enumerated().map { index, element in
            IndexedItem(index: index, originalValue: element) // Use the Identifiable initializer
        }
        // Remove extra logging
        // print("--- DEBUG: ListView.render - Created indexedItems (count: \(indexedItems.count))")
        //print("--- DEBUG: ListView - Rendering \(indexedItems.count) items for variable '\(dataVarName)'")

        // 4) Build the List using ForEach with Identifiable items
        let list = List {
            // Use Identifiable items directly in ForEach
            ForEach(indexedItems) { itemWrapper in
                // Create a mutable copy of the template for this specific row
                var rowNode = rowContentTemplate
                // Inject the current index into the node copy
                rowNode["_currentIndex"] = itemWrapper.index
                //print("--- DEBUG: ListView - Rendering row index \(itemWrapper.index)")

                // Render the component using the modified node containing the index
                return DSLViewRenderer.renderComponent(from: rowNode, context: context)
                    .id(itemWrapper.id) // Use the stable ID from the wrapper
                    /* // Optional: Debug onAppear
                     .onAppear {
                         print("--- DEBUG: ListView row \(itemWrapper.index) APPEARED")
                     }
                     */
            }
            // Potential: Add onDelete/onMove modifiers here if needed,
            // they would interact with the context via commands.
        }
        // Remove the .id modifier from the List
        // .id(itemsArray.map { String(describing: $0) }.joined().hashValue)

        // Wrap the List in AnyView for type erasure
        var contentView = AnyView(list)

        // 5) Apply modifiers if they exist
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            //print("--- DEBUG: ListView - Applying modifiers")
            contentView = modifierRegistry.apply(modifiers, to: contentView, context: context)
        }
        
        // Aplicar modificadores de ação diretamente do node
        contentView = applyActionModifiers(node: node, context: context, to: contentView)

        return contentView
    }

    // processTemplate and areEqual functions are REMOVED

    // --- register function remains unchanged ---
    public static func register() {
        DSLComponentRegistry.shared.register("list", builder: render)
        
        // Registra modificadores de base comuns (frame, padding, background, etc.)
        // Alguns podem ter efeitos limitados dependendo do listStyle.
        registerBaseViewModifiers(on: modifierRegistry)
        
        // --- Modificadores Específicos de List ---

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
                      print("⚠️ ListStyle 'sidebar' not available on this OS version.")
                      return view // Ou um fallback como .plain
                  }
            default:
                print("⚠️ ListStyle modifier: Unknown or invalid style '\(evaluatedStyle ?? "nil")'. Applying default.")
                // Default pode ser .automatic ou um estilo seguro como .insetGrouped
                if #available(iOS 14.0, macOS 11.0, *) {
                    return AnyView(view.listStyle(.insetGrouped))
                } else {
                    return AnyView(view.listStyle(.grouped))
                }
            }
        }

        modifierRegistry.register("safeAreaInset") { view, paramsAny, context in
            guard let params = paramsAny as? [String: Any],
                  let edgeStr = DSLExpression.shared.evaluate(params["edge"], context) as? String,
                  let contentNode = params["content"] as? [String: Any] else {
                print("⚠️ safeAreaInset modifier: Invalid parameters. Need 'edge' (string) and 'content' (dictionary).")
                return view // Retorna a view original se os params estiverem errados
            }

            // Avalia parâmetros opcionais
            let spacing = castToCGFloat(DSLExpression.shared.evaluate(params["spacing"], context))
            let alignmentStr = DSLExpression.shared.evaluate(params["alignment"], context) as? String

            // Renderiza o conteúdo do inset ANTES de aplicar o modificador
            let insetContent = DSLViewRenderer.renderComponent(from: contentNode, context: context)

            //print("--- DEBUG: Applying safeAreaInset to edge: \(edgeStr)")

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
                print("⚠️ safeAreaInset modifier: Invalid edge '\(edgeStr)'. Modifier not applied.")
                return view // Retorna a view original se a borda for inválida
            }
        } // Fim da closure safeAreaInset
        
        // Outros modificadores de Lista:
        // - environment(\.defaultMinListRowHeight, ...)
        // - listRowSeparator, listSectionSeparator
        // - listRowInsets
        // - refreshable (iOS 15+)
        // - swipeActions (iOS 15+)
    } // Fim de register()
}
