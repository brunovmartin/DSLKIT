// swift-helloworld-main/HelloWorld/DLSKit/Core/DLSViewRenderer.swift

import SwiftUI

public struct DSLViewRenderer {

    // NOVA FUNÇÃO: Renderiza apenas o conteúdo de uma tela e aplica modificadores de navegação
    @ViewBuilder
    public static func renderScreenContent(screen: [String: Any], context: DSLContext) -> some View {
        let body = screen["body"] as? [[String: Any]] ?? []
        let content = renderChildren(from: body, context: context) // O conteúdo da tela (ex: VStack, List)
        let navBar = screen["navigationBar"] as? [String: Any]

        // --- Lógica do Título ---
        let rawTitleExpr = navBar?["title"]
        let evaluatedTitleValue = DSLExpression.shared.evaluate(rawTitleExpr, context)
        let calculatedTitle: String = "\(evaluatedTitleValue ?? "")"

        // --- Lógica do Display Mode e Cores ---
        let displayMode = mapNavDisplayMode(navBar?["displayMode"] as? String)
//        let navBgColorExpr = navBar?["backgroundColor"]
        let navFgColorExpr = navBar?["foregroundColor"]
//        let navColorSchemeExpr = navBar?["toolbarColorScheme"]
//        let evaluatedNavBgColor = DSLExpression.shared.evaluate(navBgColorExpr, context)
        let evaluatedNavFgColor = DSLExpression.shared.evaluate(navFgColorExpr, context)
//        let evaluatedSchemeColor = DSLExpression.shared.evaluate(navColorSchemeExpr, context)
//        let navBackgroundColor = parseColor(evaluatedNavBgColor)
        let navForegroundColor = parseColor(evaluatedNavFgColor)
//        let navSchemeColor = parseColor(evaluatedNavFgColor)
        


        // --- Lógica do Botão Trailing --- REMOVIDA ---
        // let trailingButtonInfo = navBar?["trailingButton"] as? [String: Any]
        // let buttonLabelExpr = trailingButtonInfo?["label"]
        // let buttonAction = trailingButtonInfo?["onTap"]
        // let buttonLabel = DSLExpression.shared.evaluate(buttonLabelExpr, context) as? String ?? ""

        // +++ NOVA Lógica para Itens Dinâmicos na Toolbar +++
        let trailingItemsJson = navBar?["trailingItems"] as? [[String: Any]] ?? []
        let leadingItemsJson = navBar?["leadingItems"] as? [[String: Any]] ?? []


        // Aplica modificadores ao conteúdo
        content
            .navigationTitle(calculatedTitle)
            .navigationBarTitleDisplayMode(displayMode)
             .ifLet(navForegroundColor) { view, color in
                 view.tint(color)
             }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    renderChildren(from: leadingItemsJson, context: context)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    renderChildren(from: trailingItemsJson, context: context)
                }
            }

    }

    // Função render original removida ou renomeada (REMOVIDA)

    // --- renderComponent e renderChildren permanecem os mesmos ---
    public static func renderComponent(from node: [String: Any], context: DSLContext) -> AnyView {
        // --- START: Visibility Check ---
        if let visibleExpr = node["visible"] { // Verifica se a chave 'visible' existe
            // Avalia a expressão. Assume 'true' por padrão se a avaliação falhar ou não for booleana.
            let shouldShow = DSLExpression.shared.evaluate(visibleExpr, context) as? Bool ?? true

            if !shouldShow {
                // Se a expressão for avaliada como 'false', retorna EmptyView imediatamente.
                return AnyView(EmptyView())
            }
        }
        
        let type = node["type"] as? String
        if((type != nil) && type != "button"){
            if let builder = DSLComponentRegistry.shared.resolve(type!) {
                return builder(node, context)
            }
        }else{
            if let builder = DSLComponentRegistry.shared.resolve(type!) {
                return builder(node, context)
            }
        }
        return AnyView(Text("🚫 Componente desconhecido: \(node["type"] as? String ?? "?")"))
    }

    @ViewBuilder
    public static func renderChildren(from nodes: [[String: Any]], context: DSLContext) -> some View {
         ForEach(0..<nodes.count, id: \.self) { i in
             renderComponent(from: nodes[i], context: context)
         }
    }
}

