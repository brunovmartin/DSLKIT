import SwiftUI

class AlertCommands {
    static func registerAll() {
        DSLCommandRegistry.shared.register("alert.show") { (params: Any?, context: DSLContext) in
            // 1. Validar e Parsear Parâmetros
            guard let alertParams = params as? [String: Any] else {
                print("⚠️ Command 'alert.show': Invalid parameters format. Expected a Dictionary.")
                return
            }

            // Avaliar título e mensagem (podem ser expressões)
            let title = DSLExpression.shared.evaluate(alertParams["title"], context) as? String ?? ""
            let message = DSLExpression.shared.evaluate(alertParams["message"], context) as? String ?? ""
            
            // Parsear botões
            var alertButtons: [AlertButton] = []
            if let buttonDefs = alertParams["buttons"] as? [[String: Any]] {
                for buttonDef in buttonDefs {
                    let label = DSLExpression.shared.evaluate(buttonDef["label"], context) as? String ?? "Botão"
                    let roleString = DSLExpression.shared.evaluate(buttonDef["role"], context) as? String
                    let actionCommand = buttonDef["action"] as? [String: Any] // Ação é um comando DSL
                    
                    // Mapear a string da role para o enum AlertRole
                    var mappedRole: AlertRole? = nil
                    if let roleStr = roleString {
                        switch roleStr.lowercased() {
                        case "cancel": mappedRole = .cancel
                        case "destructive": mappedRole = .destructive
                        default: mappedRole = nil
                        }
                    }
                    
                    // Usar mappedRole (AlertRole?) ao criar AlertButton
                    alertButtons.append(AlertButton(label: label, role: mappedRole, action: actionCommand))
                }
            } else {
                // Se nenhum botão for fornecido, adicionar um botão "OK" padrão?
                // Ou apenas mostrar o alerta sem botões (o sistema adiciona um OK por padrão às vezes)
                // Vamos seguir o que foi definido e permitir alerta sem botões customizados, 
                // confiando no comportamento padrão do sistema ou na função createAlert.
                 print("ℹ️ Command 'alert.show': No 'buttons' array provided or invalid format. Alert might show with default dismiss button.")
            }
            
            // 2. Chamar o AlertManager na Thread Principal
            // Não precisa mais de DispatchQueue.main.async aqui, pois AlertManager já faz isso.
            AlertManager.shared.show(title: title, message: message, buttons: alertButtons)
             print("--- DEBUG: Command 'alert.show' - Requesting alert: Title='\(title)', Message='\(message)', Buttons=\(alertButtons.count)")
        }
        
        // Registrar outros comandos relacionados a alertas aqui, se necessário
        // Ex: alert.dismiss
    }
} 