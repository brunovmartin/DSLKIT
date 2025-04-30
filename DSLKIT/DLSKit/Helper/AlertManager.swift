import SwiftUI
import Combine

// Gerenciador para exibir alertas configurados pela DSL
class AlertManager: ObservableObject {
    static let shared = AlertManager()
    
    // A propriedade @Published que o App.swift observa
    @Published var alertItem: AlertItem? 

    private init() {}

    // Função para mostrar um alerta
    // Recebe os dados processados pelo AlertShowCommand
    func show(title: String, message: String, buttons: [AlertButton]) {
        // Garante que a atualização do @Published ocorra na thread principal
        DispatchQueue.main.async {
            self.alertItem = AlertItem(title: title, message: message, buttons: buttons)
        }
    }

    // Função para dispensar o alerta programaticamente (se necessário)
    func dismiss() {
        DispatchQueue.main.async {
            self.alertItem = nil
        }
    }
} 