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
        let navBgColorExpr = navBar?["backgroundColor"]
        let navFgColorExpr = navBar?["foregroundColor"]
//        let navColorSchemeExpr = navBar?["toolbarColorScheme"]
//        let evaluatedNavBgColor = DSLExpression.shared.evaluate(navBgColorExpr, context)
        let evaluatedNavFgColor = DSLExpression.shared.evaluate(navFgColorExpr, context)
//        let evaluatedSchemeColor = DSLExpression.shared.evaluate(navColorSchemeExpr, context)
//        let navBackgroundColor = parseColor(evaluatedNavBgColor)
        let navForegroundColor = parseColor(evaluatedNavFgColor)
//        let navSchemeColor = parseColor(evaluatedNavFgColor)
        


        // --- Lógica do Botão Trailing ---
        let trailingButtonInfo = navBar?["trailingButton"] as? [String: Any]
        let buttonLabelExpr = trailingButtonInfo?["label"]
        let buttonAction = trailingButtonInfo?["onTap"]
        let buttonLabel = DSLExpression.shared.evaluate(buttonLabelExpr, context) as? String ?? ""

        // Aplica modificadores ao conteúdo
        content
            .navigationTitle(calculatedTitle)
            .navigationBarTitleDisplayMode(displayMode)
             .ifLet(navForegroundColor) { view, color in
                 view.tint(.blue) // Define a cor de destaque padrão
             }
            .toolbar {
                if !buttonLabel.isEmpty, let action = buttonAction {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(buttonLabel) {
                            DSLInterpreter.shared.handleEvent(action, context: context)
                        }
                        // O tint() acima deve afetar este botão, mas podemos deixar o explícito como fallback?
                        // Ou remover este tint individual se o global funcionar.
                         .ifLet(navForegroundColor) { btn, color in btn.tint(color) }
                    }
                }
                // O botão Voltar será adicionado automaticamente pelo NavigationStack
            }
            // Adicionar outros modificadores de tela aqui se necessário (ex: background da tela)
            // Ex: .background(parseColor(DSLExpression.shared.evaluate(screen["backgroundColor"], context)))

    }

    // Função render original removida ou renomeada (REMOVIDA)

    // --- renderComponent e renderChildren permanecem os mesmos ---
    public static func renderComponent(from node: [String: Any], context: DSLContext) -> AnyView {
         if let type = node["type"] as? String,
            let builder = DSLComponentRegistry.shared.resolve(type) {
             return builder(node, context)
         } else {
             return AnyView(Text("🚫 Componente desconhecido: \(node["type"] as? String ?? "?")"))
         }
    }

    @ViewBuilder
    public static func renderChildren(from nodes: [[String: Any]], context: DSLContext) -> some View {
         ForEach(0..<nodes.count, id: \.self) { i in
             renderComponent(from: nodes[i], context: context)
         }
    }
}
