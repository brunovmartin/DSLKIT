// swift-helloworld-main/HelloWorld/DLSKit/Core/DLSViewRenderer.swift

import SwiftUI

public struct DSLViewRenderer {

    // Render the main screen (remains the same)
    public static func render(screen: [String: Any], context: DSLContext) -> some View {
        // ... (keep existing code for navigation bar, body extraction, etc.) ...
         let body = screen["body"] as? [[String: Any]] ?? []
         let content = renderChildren(from: body, context: context) // O conteúdo da tela (ex: List)
         let navBar = screen["navigationBar"] as? [String: Any]

         // --- Lógica do Título (existente) ---
         let rawTitleExpr = navBar?["title"]
         let evaluatedTitleValue = DSLExpression.shared.evaluate(rawTitleExpr, context)
         let calculatedTitle: String
         if let actualValue = evaluatedTitleValue {
             calculatedTitle = "\(actualValue)"
         } else {
             calculatedTitle = ""
         }
         //print("--- DEBUG: DSLViewRenderer - Calculated NavigationBar Title: \(calculatedTitle)")

         // --- Lógica do Display Mode e Background (existente) ---
         let displayMode = mapNavDisplayMode(navBar?["displayMode"] as? String)
         let backgroundColor = parseColor(navBar?["background"])

         // --- Lógica do Botão (existente) ---
         let trailingButtonInfo = navBar?["trailingButton"] as? [String: Any]
         let buttonLabelExpr = trailingButtonInfo?["label"] // Expressão para o texto do botão
         let buttonAction = trailingButtonInfo?["onTap"]     // Ação a ser executada
         let buttonLabel = DSLExpression.shared.evaluate(buttonLabelExpr, context) as? String ?? ""

         // --- Modifica o retorno da NavigationView ---
         return AnyView( // Keep AnyView wrapper here for the whole screen if needed
             NavigationView {
                 content // Aplica os modificadores ao conteúdo DENTRO da NavigationView
                     .navigationTitle(calculatedTitle) // Título (existente)
                     .navigationBarTitleDisplayMode(displayMode) // Modo de exibição (existente)
                     // Modificador de fundo (existente)
                     .ifLet(backgroundColor) { view, color in
                         view
                             .toolbarBackground(color, for: .navigationBar)
                             .toolbarBackground(.visible, for: .navigationBar)
                     }
                     // --- Toolbar para o botão (existente) ---
                     .toolbar {
                         if !buttonLabel.isEmpty, let action = buttonAction {
                             ToolbarItem(placement: .navigationBarTrailing) {
                                 Button(buttonLabel) {
                                     //print("--- DEBUG: Trailing navigation button tapped. Action: \(action)")
                                     DSLInterpreter.shared.handleEvent(action, context: context)
                                 }
                             }
                         }
                     }
             }
             // No need to add .environmentObject(context) here if it's already done in App.swift
             // .environmentObject(context)
         )
    }


    // --- CHANGE THIS FUNCTION ---
    // Change return type from 'some View' to 'AnyView'
    // Remove @ViewBuilder if it causes issues with AnyView return type
    public static func renderComponent(from node: [String: Any], context: DSLContext) -> AnyView {
         if let type = node["type"] as? String,
            let builder = DSLComponentRegistry.shared.resolve(type) {
             // The builder already returns AnyView, so just return it directly
             return builder(node, context)
         } else {
             // Wrap the fallback Text in AnyView
             return AnyView(Text("🚫 Componente desconhecido: \(node["type"] as? String ?? "?")"))
         }
    }
    // --- END OF CHANGE ---


    // This function uses renderComponent, which now returns AnyView.
    // It needs to be adjusted or remain as is if @ViewBuilder handles AnyView correctly.
    // Let's keep @ViewBuilder for now, as it *should* work with AnyView.
    @ViewBuilder
    public static func renderChildren(from nodes: [[String: Any]], context: DSLContext) -> some View {
         ForEach(0..<nodes.count, id: \.self) { i in
             renderComponent(from: nodes[i], context: context) // This now returns AnyView
         }
    }
}
