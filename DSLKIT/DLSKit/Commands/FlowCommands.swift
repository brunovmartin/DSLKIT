// swift-helloworld-main/HelloWorld/DLSKit/Commands/FlowCommands.swift
import Foundation

public class FlowCommands {
    public static func registerAll() {

        // ATUALIZAR ASSINATURA: payload é Any?
        DSLCommandRegistry.shared.register("if") { payload, context in
            logDebug("--- DEBUG: IF Command - Received payload: \(String(describing: payload))")
            guard let ifData = payload as? [String: Any],
                  let conditionExpr = ifData["condition"] else {
                //logDebug("⚠️ Comando 'if' mal formatado ou sem condição. Payload recebido: \(String(describing: payload))")
                return
            }

            let result = DSLExpression.shared.evaluate(conditionExpr, context) as? Bool ?? false
            logDebug("--- DEBUG: IF Command - Condition evaluated to: \(result)")
            let branchKey = result ? "then" : "else"
            guard let branch = ifData[branchKey] else {
                // Branch não encontrada, não faz nada.
                logDebug("--- DEBUG: IF Command - Branch '\(branchKey)' not found.")
                return
            }
            logDebug("--- DEBUG: IF Command - Found branch '\(branchKey)'. Content: \(branch)")

            // MODIFICAÇÃO AQUI: Só aceita um *único* objeto de comando.
            // Se for um array, ou qualquer outra coisa, será ignorado.
            if let singleCommand = branch as? [String: Any] {
                logDebug("--- DEBUG: IF Command - Executing single command in '\(branchKey)' branch: \(singleCommand)")
                // Executa o comando único. Se este comando for um "sequence",
                // o manipulador de "sequence" será chamado e processará a lista interna.
                DSLCommandRegistry.shared.execute(singleCommand, context: context)
            }
            // REMOVIDO: Bloco que tratava 'branch' como [[String: Any]] (array)
            /*
            else if let commands = branch as? [[String: Any]] {
                 logDebug("⚠️ Deprecated: 'if' command branch '\(branchKey)' should contain a single command object (e.g., 'sequence'), not an array. Executing sequence anyway.")
                 for cmd in commands {
                     DSLCommandRegistry.shared.execute(cmd, context: context)
                 }
            }
            */
             else {
                // Se não for um objeto de comando válido, avisa.
                logDebug("⚠️ Comando 'if' - Branch '\(branchKey)' não contém um objeto de comando válido. Conteúdo: \(branch)")
            }
        }

        // ATUALIZAR ASSINATURA: payload é Any?
        DSLCommandRegistry.shared.register("sequence") { payload, context in
            // Tenta converter o payload para a lista de comandos esperada pelo 'sequence'
            guard let commandList = payload as? [[String: Any]] else {
                //logDebug("⚠️ Comando 'sequence' inválido: payload não é uma lista de comandos. Payload: \(String(describing: payload))")
                return
            }

            //logDebug("--- DEBUG: FlowCommands 'sequence' - Executing command list.")
            for cmd in commandList {
                DSLCommandRegistry.shared.execute(cmd, context: context)
            }
        }
        
        // Comando para navegar (empilhar) para outra tela
        DSLCommandRegistry.shared.register("navigate") { payload, context in // Contexto não é usado diretamente aqui, mas mantido por padrão
            guard let screenId = payload as? String else {
                logDebug("⚠️ Comando 'navigate' inválido: payload não é um ID de tela (String). Payload: \(String(describing: payload))")
                return
            }
            logDebug("--- DEBUG: NAVIGATE Command - Requesting push for screen: \(screenId)")
            // Chama o método do Interpreter que modifica o @Published navigationPath
            DSLInterpreter.shared.pushScreen(withId: screenId)
        }
        
        // Comando para voltar (desempilhar) a tela atual programaticamente
        DSLCommandRegistry.shared.register("pop") { _, context in // Payload e contexto não são usados
            logDebug("--- DEBUG: POP Command - Requesting pop")
            // Chama o método do Interpreter que modifica o @Published navigationPath
            DSLInterpreter.shared.popScreen()
        }
    }
}
