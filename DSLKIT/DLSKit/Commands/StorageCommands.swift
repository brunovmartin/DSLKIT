import Foundation


public class StorageCommands {
    /// Registra os comandos relacionados ao Storage (UserDefaults).
    public static func registerAll() {
        
        // Comando 'Storage.set'
        DSLCommandRegistry.shared.register("Storage.set") { params, context in
            guard let setParams = params as? [String: Any],
                  // A chave pode ser uma string literal ou uma expressão que avalia para string
                  let key = DSLExpression.shared.evaluate(setParams["key"], context) as? String,
                  let valueExpr = setParams["value"] else { // O valor a ser salvo
                logDebug("⚠️ Command 'Storage.set': Invalid parameters. Expected { \"key\": \"string_expr\", \"value\": any_expr }.")
                return
            }
            // Avalia o valor ANTES de salvar
            let valueToStore = DSLExpression.shared.evaluate(valueExpr, context)
            StorageHelper.set(key: key, value: valueToStore)
        }
        
        // Adicionar outros comandos de storage aqui no futuro (ex: Storage.remove)
    }
}
