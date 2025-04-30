import SwiftUI

// Enum para representar a intenção da role do botão
enum AlertRole {
    case cancel
    case destructive
    // Adicione outros casos se necessário no futuro
}

// Estrutura para definir um botão no alerta DSL
struct AlertButton {
    let label: String
    let role: AlertRole? // Usa o enum customizado
    let action: [String: Any]? // Comando DSL a ser executado
}

// Estrutura para representar o alerta a ser exibido via AlertManager
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let buttons: [AlertButton] // Array de botões customizados
} 