// swift-helloworld-main/HelloWorld/DLSKit/Commands/FlowCommands.swift
import Foundation

public class FlowCommands {
    public static func registerAll() {

        // ATUALIZAR ASSINATURA: payload é Any?
        DSLCommandRegistry.shared.register("if") { payload, context in
            // Tenta converter o payload para o dicionário esperado pelo 'if'
            guard let ifData = payload as? [String: Any],
                  let conditionExpr = ifData["condition"] else {
                //print("⚠️ Comando 'if' mal formatado ou sem condição. Payload recebido: \(String(describing: payload))")
                return
            }

            let result = DSLExpression.shared.evaluate(conditionExpr, context) as? Bool ?? false
            //print("--- DEBUG: FlowCommands 'if' - Condition result: \(result)")
            let branchKey = result ? "then" : "else"
            guard let branch = ifData[branchKey] else {
                //print("--- DEBUG: FlowCommands 'if' - Branch '\(branchKey)' not found or empty.")
                return
            }

            if let singleCommand = branch as? [String: Any] {
                //print("--- DEBUG: FlowCommands 'if' - Executing single command in '\(branchKey)' branch.")
                DSLCommandRegistry.shared.execute(singleCommand, context: context)
            } else if let commands = branch as? [[String: Any]] {
                //print("--- DEBUG: FlowCommands 'if' - Executing command list in '\(branchKey)' branch.")
                for cmd in commands {
                    DSLCommandRegistry.shared.execute(cmd, context: context)
                }
            } else {
                //print("⚠️ Comando 'if' - Branch '\(branchKey)' não é um comando ou lista de comandos válidos.")
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
    }
}
