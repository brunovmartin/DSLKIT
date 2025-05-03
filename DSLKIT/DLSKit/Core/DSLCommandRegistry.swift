// swift-helloworld-main/HelloWorld/DLSKit/Core/DSLCommandRegistry.swift
import Foundation // Certifique-se que Foundation está importado

public class DSLCommandRegistry {
    public static let shared = DSLCommandRegistry()

    // MUDE A ASSINATURA AQUI para aceitar Any? como payload
    private var registry: [String: (Any?, DSLContext) -> Void] = [:] // <<-- MUDANÇA AQUI

    private init() {
        // registerDefaults() // REMOVIDO DAQUI
    }

    // MUDE A ASSINATURA AQUI também
    public func register(_ name: String, _ fn: @escaping (Any?, DSLContext) -> Void) { // <<-- MUDANÇA AQUI
        registry[name] = fn
    }

    public func execute(_ command: [String: Any], context: DSLContext) {
        guard let name = command.keys.first,
              let params = command[name],
              let fn = registry[name] else {
            logDebug("⚠️ CommandRegistry: Unknown command or invalid format: \(command)")
            return
        }
        // logDebug("--- DEBUG: CommandRegistry executing command: \(name) with params: \(String(describing: params))")
        fn(params, context)
    }

    public func registerDefaults() {
        // Comando 'set' para modificar variáveis no contexto
        register("set") { params, context in
            guard let setParams = params as? [String: Any],
                  let varPath = setParams["var"] as? String,
                  let valueExpr = setParams["value"] else { // 'value' pode ser qualquer coisa
                logDebug("⚠️ Command 'set': Invalid parameters. Need 'var' (String) and 'value'.")
                return
            }
            // Avalia o valor ANTES de definir no contexto
            let valueToSet = DSLExpression.shared.evaluate(valueExpr, context)
            // logDebug("--- DEBUG: Command 'set' - Setting var '\(varPath)' to value: \(String(describing: valueToSet))")
            context.set(varPath, to: valueToSet ?? "?")
        }

        // Comando 'navigate' para navegação
        register("navigate") { params, context in
            // O parâmetro pode ser o ID da tela (String) ou um dicionário {"screenId": "..."}
            var screenId: String? = nil
            if let id = params as? String {
                screenId = id
            } else if let dict = params as? [String: Any] {
                screenId = DSLExpression.shared.evaluate(dict["screenId"], context) as? String
            }
            
            guard let id = screenId else {
                logDebug("⚠️ Command 'navigate': Invalid parameter. Expected screen ID (String).")
                return
            }
            // logDebug("--- DEBUG: Command 'navigate' - Navigating to screen: \(id)")
            DispatchQueue.main.async { // Garante que a mudança de UI ocorra na thread principal
                 DSLInterpreter.shared.pushScreen(withId: id)
            }
        }
        
        // Comando 'goBack'
        register("goBack") { params, context in
             // logDebug("--- DEBUG: Command 'goBack' - Popping screen")
             DispatchQueue.main.async { // Garante que a mudança de UI ocorra na thread principal
                 DSLInterpreter.shared.popScreen()
             }
         }
        
        // Comando 'logDebug' para debug
        register("logDebug") { params, context in
            // Avalia o parâmetro (que é o valor a ser impresso)
            let valueTologDebug = DSLExpression.shared.evaluate(params, context)
            // Usa a função logDebug() do Swift
            logDebug("DSL logDebug >>> \(String(describing: valueTologDebug ?? "nil"))")
        }

        // Adicionar outros comandos padrão aqui...
        // Ex: 'if', 'switch', 'forEach' (para lógica), 'httpGet', 'showDialog', etc.
        register("if") { params, context in
             guard let ifParams = params as? [String: Any],
                   let conditionExpr = ifParams["condition"] else {
                 logDebug("⚠️ Command 'if': Invalid parameters. Missing 'condition'.")
                 return
             }
             
             let conditionResult = DSLExpression.shared.evaluate(conditionExpr, context) as? Bool ?? false
             // logDebug("--- DEBUG: Command 'if' - Condition evaluated to: \(conditionResult)")

             if conditionResult {
                 if let thenAction = ifParams["then"] {
                     // logDebug("--- DEBUG: Command 'if' - Executing 'then' branch")
                     // handleEvent pode lidar com comando único ou sequência
                     DSLInterpreter.shared.handleEvent(thenAction, context: context)
                 }
             } else {
                 if let elseAction = ifParams["else"] {
                     // logDebug("--- DEBUG: Command 'if' - Executing 'else' branch")
                     DSLInterpreter.shared.handleEvent(elseAction, context: context)
                 }
             }
         }
        
        // Comando 'sequence' (embora handleEvent já trate, pode ser útil registrar explicitamente?)
        // O handleEvent já itera sobre arrays, então registrar 'sequence' aqui pode ser redundante
        // a menos que queiramos adicionar lógica específica à execução sequencial.
        // Por ora, vamos confiar no handleEvent.
        // register("sequence") { params, context in
        //     guard let sequenceArray = params as? [[String: Any]] else {
        //         logDebug("⚠️ Command 'sequence': Invalid parameters. Expected an array of commands.")
        //         return
        //     }
        //     DSLInterpreter.shared.handleEvent(sequenceArray, context: context) // Reencaminha para handleEvent
        // }

        // Chamar funções de registro modulares
       
        
        VariableCommands.registerAll()
        ArrayCommands.registerAll()
        FlowCommands.registerAll()
        StorageCommands.registerAll()
        AlertCommands.registerAll()
        HttpRequestCommand.registerAll()
    } // Fim de registerDefaults
}
