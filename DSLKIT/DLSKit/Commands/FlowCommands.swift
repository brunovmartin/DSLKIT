// swift-helloworld-main/HelloWorld/DLSKit/Commands/FlowCommands.swift
import Foundation

public class FlowCommands {
    public static func registerAll() {

        // ATUALIZAR ASSINATURA: payload é Any?
        DSLCommandRegistry.shared.register("if") { payload, context in
            print("--- DEBUG: IF Command - Received payload: \(String(describing: payload))")
            guard let ifData = payload as? [String: Any],
                  let conditionExpr = ifData["condition"] else {
                //print("⚠️ Comando 'if' mal formatado ou sem condição. Payload recebido: \(String(describing: payload))")
                return
            }

            let result = DSLExpression.shared.evaluate(conditionExpr, context) as? Bool ?? false
            print("--- DEBUG: IF Command - Condition evaluated to: \(result)")
            let branchKey = result ? "then" : "else"
            guard let branch = ifData[branchKey] else {
                //print("--- DEBUG: FlowCommands 'if' - Branch '\(branchKey)' not found or empty.")
                return
            }
            print("--- DEBUG: IF Command - Selected branch '\(branchKey)'. Content: \(branch)")

            if let singleCommand = branch as? [String: Any] {
                //print("--- DEBUG: FlowCommands 'if' - Executing single command in '\(branchKey)' branch.")
                print("--- DEBUG: IF Command - Executing single command in '\(branchKey)' branch...")
                DSLCommandRegistry.shared.execute(singleCommand, context: context)
            } else if let commands = branch as? [[String: Any]] {
                //print("--- DEBUG: FlowCommands 'if' - Executing command list in '\(branchKey)' branch.")
                print("--- DEBUG: IF Command - Executing command list in '\(branchKey)' branch...")
                for cmd in commands {
                    DSLCommandRegistry.shared.execute(cmd, context: context)
                }
            } else {
                //print("⚠️ Comando 'if' - Branch '\(branchKey)' não é um comando ou lista de comandos válidos.")
                print("⚠️ Comando 'if' - Branch '\(branchKey)' não é um comando ou lista válidos.")
            }
        }

        // ATUALIZAR ASSINATURA: payload é Any?
        DSLCommandRegistry.shared.register("sequence") { payload, context in
            // Tenta converter o payload para a lista de comandos esperada pelo 'sequence'
            guard let commandList = payload as? [[String: Any]] else {
                //print("⚠️ Comando 'sequence' inválido: payload não é uma lista de comandos. Payload: \(String(describing: payload))")
                return
            }

            //print("--- DEBUG: FlowCommands 'sequence' - Executing command list.")
            for cmd in commandList {
                DSLCommandRegistry.shared.execute(cmd, context: context)
            }
        }
        
        // Comando para navegar (empilhar) para outra tela
        DSLCommandRegistry.shared.register("navigate") { payload, context in // Contexto não é usado diretamente aqui, mas mantido por padrão
            guard let screenId = payload as? String else {
                print("⚠️ Comando 'navigate' inválido: payload não é um ID de tela (String). Payload: \(String(describing: payload))")
                return
            }
            print("--- DEBUG: NAVIGATE Command - Requesting push for screen: \(screenId)")
            // Chama o método do Interpreter que modifica o @Published navigationPath
            DSLInterpreter.shared.pushScreen(withId: screenId)
        }
        
        // Comando para voltar (desempilhar) a tela atual programaticamente
        DSLCommandRegistry.shared.register("pop") { _, context in // Payload e contexto não são usados
            print("--- DEBUG: POP Command - Requesting pop")
            // Chama o método do Interpreter que modifica o @Published navigationPath
            DSLInterpreter.shared.popScreen()
        }
    }
}
