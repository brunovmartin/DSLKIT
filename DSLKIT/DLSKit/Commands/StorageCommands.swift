import Foundation

/// Registra os comandos relacionados ao Storage (UserDefaults).
func registerStorageCommands(on registry: DSLCommandRegistry) {
    
    // Comando 'Storage.set'
    registry.register("Storage.set") { params, context in
        guard let setParams = params as? [String: Any],
              // A chave pode ser uma string literal ou uma expressão que avalia para string
              let key = DSLExpression.shared.evaluate(setParams["key"], context) as? String,
              let valueExpr = setParams["value"] else { // O valor a ser salvo
            print("⚠️ Command 'Storage.set': Invalid parameters. Expected { \"key\": \"string_expr\", \"value\": any_expr }.")
            return
        }
        // Avalia o valor ANTES de salvar
        let valueToStore = DSLExpression.shared.evaluate(valueExpr, context)
        StorageHelper.set(key: key, value: valueToStore)
    }
    
    // Adicionar outros comandos de storage aqui no futuro (ex: Storage.remove)
} 