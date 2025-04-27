import Foundation
import SwiftUI

public class DSLAppEngine {
    public static let shared = DSLAppEngine()
    // Remova a criação interna de contexto
    // public let context: DSLContext
    public var initialScreenId: String?
    public var screens: [String: [String: Any]] = [:]

    // Contexto será recebido externamente
    private var currentContext: DSLContext?

    private init() { // Só carrega a estrutura JSON
        guard let url = Bundle.main.url(forResource: "app.compiled", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            fatalError("Não foi possível carregar app.compiled.json")
        }

        // NÃO cria mais o contexto aqui
        /*
        if let data = raw["context"] as? [String: Any] {
            context = DSLContext(initial: data)
        }else{
            context = DSLContext(initial: [:])
        }
        */

        // Registra comandos e operadores (isso está ok)
        // RegistrySetup.registerAll() // Movido para App.swift para garantir execução antes de start

        // Registra as telas
        if let screenList = raw["screens"] as? [[String: Any]] {
            for screen in screenList {
                if let id = screen["id"] as? String {
                    screens[id] = screen
                }
            }
        }

        // Define tela inicial
        self.initialScreenId = raw["mainScreen"] as? String
    }

    // Modifica start para receber o contexto
    public func start(context: DSLContext) {
        self.currentContext = context // Armazena o contexto recebido

        // Carrega os dados iniciais do JSON NO CONTEXTO RECEBIDO
        if let url = Bundle.main.url(forResource: "app.compiled", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let initialData = raw["context"] as? [String: Any] {
            
            // --- Primeira Passagem: Definir valores brutos --- 
            print("--- DEBUG AppEngine.start: First Pass - Setting raw initial values ---")
            for (key, value) in initialData {
                print("    Setting raw: \(key) = \(value)")
                context.set(key, to: value)
            }
            
            // --- Segunda Passagem: Avaliar e atualizar expressões --- 
            print("--- DEBUG AppEngine.start: Second Pass - Evaluating expressions ---")
            for (key, rawValue) in initialData { // Iterar sobre os dados originais
                // Avaliar SOMENTE se o valor bruto parece ser uma expressão 
                // (Ex: um dicionário, que é como representamos {"var":...} ou operadores)
                if rawValue is [String: Any] { 
                    print("    Evaluating expression for key: \(key), rawValue: \(rawValue)")
                    let evaluatedValue = DSLExpression.shared.evaluate(rawValue, context) ?? NSNull()
                    print("    Updating context: \(key) = \(evaluatedValue)")
                    context.set(key, to: evaluatedValue) // Atualiza com o valor avaliado
                } else {
                    // Valores literais (String, Int, Bool, etc.) já foram definidos corretamente na primeira passagem
                     print("    Skipping literal for key: \(key), value: \(rawValue)")
                }
            }
        }

        guard let id = initialScreenId, let screen = screens[id] else {
            //("🚫 Tela inicial não encontrada.")
            return
        }

        // Apresenta usando o contexto recebido
        DSLInterpreter.shared.present(screen: screen, context: context)
    }

    // Adapte navigate se necessário para usar self.currentContext
    public func navigate(to id: String) {
        guard let screen = screens[id], let context = self.currentContext else {
            //print("🚫 Tela '\(id)' não encontrada ou contexto não definido.")
            return
        }
        DSLInterpreter.shared.present(screen: screen, context: context) // Usa o contexto atual
    }

    // Função para obter a definição da tela por ID
    public func getScreenDefinition(byId screenId: String) -> [String: Any]? {
        return screens[screenId]
    }
}
