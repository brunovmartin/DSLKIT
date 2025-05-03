import Foundation
import SwiftUI

// Definir o tipo de erro customizado
enum DSLEngineError: Error, LocalizedError {
    case jsonFileNotFound
    case jsonRootNotDictionary
    
    var errorDescription: String? {
        switch self {
        case .jsonFileNotFound:
            return "Arquivo JSON 'app.compiled.json' não encontrado no Bundle."
        case .jsonRootNotDictionary:
            return "O conteúdo raiz do JSON não é um Dicionário [String: Any]."
        }
    }
}

// MARK: - JSON Pre-check Function

/// Realiza verificações básicas de sintaxe no JSON (balanceamento de chaves/colchetes).
/// Retorna uma string de erro com o número da linha se um problema for detectado, ou nil se ok.
private func precheckJSON(data: Data) -> String? {
    guard let jsonString = String(data: data, encoding: .utf8) else {
        return "Erro interno: Não foi possível converter os dados JSON para String UTF-8."
    }
    let lines = jsonString.components(separatedBy: .newlines)
    var braceBalance = 0
    var bracketBalance = 0
    // Rastreamento básico de strings (não lida com escapes complexos)
    var isInsideString = false

    for (index, line) in lines.enumerated() {
        let lineNumber = index + 1
        for char in line {
            if char == "\"" {
                // Simplificação: assume que não há aspas escapadas dentro da string
                isInsideString.toggle()
            }
            // Só verifica balanceamento fora de strings literais
            if !isInsideString {
                switch char {
                case "{": braceBalance += 1
                case "}": braceBalance -= 1
                case "[": bracketBalance += 1
                case "]": bracketBalance -= 1
                default: break
                }
            }
            // Se em algum momento o balanceamento ficar negativo, há um erro
            if braceBalance < 0 {
                return "Erro de sintaxe provável: '}' extra ou faltando antes na linha \(lineNumber)."
            }
            if bracketBalance < 0 {
                return "Erro de sintaxe provável: ']' extra ou faltando antes na linha \(lineNumber)."
            }
        }
        // Se uma linha terminar dentro de uma string, é um erro (JSON não permite strings multi-linha literais assim)
        // Nota: Isso pode dar falso positivo se a última linha for só parte de uma string longa.
        // if isInsideString && index == lines.count - 1 { // Só checa na última linha para evitar falsos positivos
        //     return "Erro de sintaxe provável: String não terminada no final do arquivo (linha \(lineNumber))."
        // }
         // Resetar isInsideString no final de cada linha pode não ser correto para strings que cruzam linhas
         // mas JSON padrão não permite strings literais multi-linha sem \n.
         // Vamos considerar que se isInsideString for true no fim da linha (sem ser a última), é um erro.
         if isInsideString && line.last != "\"" { // Se termina dentro de uma string iniciada nesta linha
             // Cuidado com linhas que são continuação de string
             // Esta lógica é imperfeita. O melhor é só checar o balanceamento final.
         }
    }

    // Verificação final de balanceamento
    if braceBalance != 0 {
        return "Erro de sintaxe provável: Número total de chaves '{' e '}' não corresponde no arquivo."
    }
    if bracketBalance != 0 {
         return "Erro de sintaxe provável: Número total de colchetes '[' e ']' não corresponde no arquivo."
    }

    return nil // Nenhuma inconsistência básica encontrada
}

public class DSLAppEngine {
    public static let shared = DSLAppEngine()
    // Remova a criação interna de contexto
    // public let context: DSLContext
    public var initialScreenId: String?
    public var screens: [String: [String: Any]] = [:]
    public var tabDefinitions: [[String: Any]]? = nil 

    // Contexto será recebido externamente
    private var currentContext: DSLContext?

    private init() { // Só carrega a estrutura JSON
        // Use do-catch para melhor erro de carregamento/parsing
        do {
            guard let url = Bundle.main.url(forResource: "app.compiled", withExtension: "json") else {
                throw DSLEngineError.jsonFileNotFound
            }
            let data = try Data(contentsOf: url)
            
            // ** Executa a pré-verificação básica **
            if let precheckErrorMsg = precheckJSON(data: data) {
                // Se a pré-verificação falhar, imprime o erro e termina
                logDebug("\n🚨🚨🚨 ERRO BÁSICO DE SINTAXE DETECTADO EM app.compiled.json 🚨🚨🚨")
                logDebug("--------------------------------------------------------------")
                logDebug(precheckErrorMsg)
                logDebug("--------------------------------------------------------------")
                logDebug("Corrija o problema indicado acima e tente novamente.")
                fatalError("Falha ao inicializar DSLAppEngine devido a erro básico no JSON.")
            }
            
            // ** Se a pré-verificação passar, tenta o parsing completo **
            guard let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw DSLEngineError.jsonRootNotDictionary
            }

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

        } catch let error as DSLEngineError {
             // Captura nossos erros customizados
             fatalError("Erro ao carregar DSL: \(error.localizedDescription)")
        } catch {
             // Captura outros erros (Data(contentsOf:), JSONSerialization)
             // Imprime a descrição do erro pego
             logDebug("\n🚨🚨🚨 ERRO FATAL AO CARREGAR/PROCESSAR app.compiled.json 🚨🚨🚨")
             logDebug("---------------------------------------------------------")
             logDebug("Erro: \(error.localizedDescription)")
             logDebug("Detalhes: \(error)") // Imprime a descrição completa do erro
             logDebug("---------------------------------------------------------")
             logDebug("Verifique se o arquivo 'app.compiled.json' está no Bundle e se o formato JSON é válido.")
             logDebug("Você pode usar um validador JSON online para ajudar a encontrar o erro.")
             logDebug("---------------------------------------------------------")
             fatalError("Falha ao inicializar DSLAppEngine devido a erro no JSON.") // Ainda termina, mas com mais info no log
        }
    }

    // Modifica start para receber o contexto e o interpreter
    public func start(context: DSLContext, interpreter: DSLInterpreter) {
        self.currentContext = context // Armazena o contexto recebido

        // Carrega os dados iniciais do JSON NO CONTEXTO RECEBIDO
        if let url = Bundle.main.url(forResource: "app.compiled", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let initialData = raw["context"] as? [String: Any] {
            
            // --- Primeira Passagem: Definir valores brutos ---
            logDebug("--- DEBUG AppEngine.start: First Pass - Setting raw initial values ---")
            for (key, value) in initialData {
                logDebug("    Setting raw: \(key) = \(value)")
                context.set(key, to: value)
            }
            
            // --- Segunda Passagem: Avaliar e atualizar expressões ---
            // Mantém a avaliação síncrona por enquanto
            logDebug("--- DEBUG AppEngine.start: Second Pass - Evaluating expressions ---")
            for (key, rawValue) in initialData { // Iterar sobre os dados originais
                if rawValue is [String: Any] {
                    logDebug("    Evaluating expression for key: \(key), rawValue: \(rawValue)")
                    // Chamada síncrona
                    let evaluatedValue = DSLExpression.shared.evaluate(rawValue, context) ?? NSNull()
                    logDebug("    Updating context: \(key) = \(evaluatedValue)")
                    context.set(key, to: evaluatedValue)
                } else {
                    logDebug("    Skipping literal for key: \(key), value: \(rawValue)")
                }
            }
            
            // --- Após a conclusão da avaliação síncrona ---
            // Usa Task/MainActor para atualizar o estado @Published e apresentar a UI
            Task {
                
                //try? await Task.sleep(for: .seconds(10))
                await MainActor.run { // Garante execução na Main Thread
                    
                    // Apresenta a tela inicial somente APÓS o contexto estar pronto
                    guard let id = self.initialScreenId, let screen = self.screens[id] else {
                        logDebug("🚫 Tela inicial não encontrada após carregamento.")
                        return
                    }

                    // Marca o carregamento como completo APÓS apresentar ao interpreter
                    // Isso garante que o interpreter.currentContext está definido antes da UI principal tentar renderizar
                    context.waitForUpdates {
                         logDebug("--- DEBUG AppEngine.start: Evaluation Complete & Interpreter Presented - Setting isInitialLoadComplete = true ---")
                         context.isInitialLoadComplete = true
                         logDebug("--- Final Context Storage after updates ---")
                         logDebug(context.storage)
                        
                        // --- VERIFICA SE HÁ TABS (APENAS PARA usesTabs()) ---
                        if let tabs = raw["tabs"] as? [[String: Any]] {
                            self.tabDefinitions = tabs
                            logDebug("ℹ️ Engine Init: Definição 'tabs' encontrada.")
                            // Se usa tabs, o App.swift vai cuidar de apresentar a view inicial de cada tab.
                            // O interpreter ainda precisa saber o contexto, mas não necessariamente apresentar uma tela específica aqui.
                            // Talvez uma chamada diferente para o interpreter ou apenas definir o contexto?
                            // Por enquanto, vamos deixar o present aqui, assumindo que o ID inicial ainda é relevante
                            // mesmo com tabs, talvez para estado inicial ou fallback.
                            interpreter.present(screen: screen, context: context) // Informa o interpreter sobre o contexto e tela "raiz"

                        } else {
                            self.tabDefinitions = nil
                            logDebug("ℹ️ Engine Init: Definição 'tabs' NÃO encontrada.")
                            // Se não usa tabs, o interpreter apresenta a tela inicial única.
                            interpreter.present(screen: screen, context: context) // Informa o interpreter sobre o contexto e tela inicial
                        }
                        
                     }
                }
            } // Fim da Task
        } // Fim do if let initialData
    }
    
    // Helper para verificar se a configuração JSON continha tabs
    public func usesTabs() -> Bool {
        return self.tabDefinitions != nil
    }

    // Adapte navigate se necessário para usar self.currentContext
    public func navigate(to id: String) {
        guard let screen = screens[id], let context = self.currentContext else {
            //logDebug("🚫 Tela '\(id)' não encontrada ou contexto não definido.")
            return
        }
        DSLInterpreter.shared.present(screen: screen, context: context) // Usa o contexto atual
    }

    // Função para obter a definição da tela por ID
    public func getScreenDefinition(byId screenId: String) -> [String: Any]? {
        return screens[screenId]
    }
}
