import SwiftUI

public struct ListView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    // Wrapper struct to make items Identifiable for ForEach
    private struct IndexedItem: Identifiable {
        let id = UUID() // Use UUID for unique ID if data has no inherent ID
        let index: Int
        let originalValue: Any // Keep the original value if needed, though maybe not directly used here
    }

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // 1) Extract data source
        guard let dataExpr = node["data"] as? [String: Any],
              let dataVarName = dataExpr["var"] as? String else {
            return AnyView(Text("List Error: Missing or invalid 'data' source definition: \(String(describing: node["data"]))"))
        }

        // 2) Extract row template
        guard let rowContentTemplate = node["rowContent"] as? [String: Any] else {
            return AnyView(Text("List Error: Missing 'rowContent' template"))
        }

        // 3) Get data and wrap for ForEach
        let itemsArray = context.get(dataVarName) as? [Any] ?? []
        // Create Identifiable items for ForEach
        let indexedItems: [IndexedItem] = itemsArray.enumerated().map { index, element in
            IndexedItem(index: index, originalValue: element)
        }
        //print("--- DEBUG: ListView - Rendering \(indexedItems.count) items for variable '\(dataVarName)'")

        // 4) Build the List using ForEach with Identifiable items
        let list = List {
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

        // Wrap the List in AnyView for type erasure
        var contentView = AnyView(list)

        // 5) Apply modifiers if they exist
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            //print("--- DEBUG: ListView - Applying modifiers")
            contentView = modifierRegistry.apply(modifiers, to: contentView, context: context)
        }

        return contentView
    }

    // processTemplate and areEqual functions are REMOVED

    // --- register function remains unchanged ---
    public static func register() {
        DSLComponentRegistry.shared.register("list", builder: render)
        
        // Inside ListView.register()

        modifierRegistry.register("listStyle") { view, paramsAny, context in
            let evaluatedStyle = DSLExpression.shared.evaluate(paramsAny, context) as? String

            switch evaluatedStyle?.lowercased() {
            case "plain":
                return AnyView(view.listStyle(.plain))
            case "grouped":
                return AnyView(view.listStyle(.grouped))
            case "inset":
                return AnyView(view.listStyle(.inset))
            case "insetgrouped":
                return AnyView(view.listStyle(.insetGrouped))
            // Add other styles like .sidebar if needed
            default:
//                print("⚠️ ListStyle modifier: Unknown or invalid style '\(evaluatedStyle ?? "nil")'. Applying default.")
                // Applying .automatic or .insetGrouped is often a safe default
                 return AnyView(view.listStyle(.insetGrouped))
            }
        }

        modifierRegistry.register("safeAreaInset") { view, paramsAny, context in
            guard let params = paramsAny as? [String: Any],
                  let edgeStr = params["edge"] as? String,
                  let contentNode = params["content"] as? [String: Any] else {
                //print("⚠️ safeAreaInset modifier: Invalid parameters. Need 'edge' (string) and 'content' (dictionary).")
                return view // Retorna a view original se os params estiverem errados
            }

            // Opcional: Pega o spacing, se definido
            let spacing = castToCGFloat(params["spacing"]) // Usa helper existente

            // Renderiza o conteúdo do inset ANTES de aplicar o modificador
            let insetContent = DSLViewRenderer.renderComponent(from: contentNode, context: context)

            //print("--- DEBUG: Applying safeAreaInset to edge: \(edgeStr)")

            // Chama a assinatura correta baseada na string da borda
            switch edgeStr.lowercased() {
            case "top":
                // Para bordas verticais, o alinhamento é horizontal (default .center)
                return AnyView(view.safeAreaInset(edge: .top, alignment: .center, spacing: spacing) {
                    insetContent
                })
            case "bottom":
                // Para bordas verticais, o alinhamento é horizontal (default .center)
                return AnyView(view.safeAreaInset(edge: .bottom, alignment: .center, spacing: spacing) {
                    insetContent
                })
            case "leading":
                // Para bordas horizontais, o alinhamento é vertical (default .center)
                return AnyView(view.safeAreaInset(edge: .leading, alignment: .center, spacing: spacing) {
                    insetContent
                })
            case "trailing":
                // Para bordas horizontais, o alinhamento é vertical (default .center)
                return AnyView(view.safeAreaInset(edge: .trailing, alignment: .center, spacing: spacing) {
                    insetContent
                })
            default:
                //print("⚠️ safeAreaInset modifier: Invalid edge '\(edgeStr)'. Modifier not applied.")
                return view // Retorna a view original se a borda for inválida
            }
        }
        // Register other ListView-specific modifiers here (if any)
    }
}
