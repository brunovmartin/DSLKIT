import Foundation

/// Registra os operadores relacionados ao Storage (UserDefaults).
public class StorageOperators { // Ou MathOperators
    public static func registerAll() {
        
        // Operador 'Storage.get'
        DSLOperatorRegistry.shared.register("Storage.get") { input, context in
            // O input deve ser o dicionário de parâmetros: { "key": "nomeDaChave" }
            // ou apenas a chave como string: "nomeDaChave"
            
            var key: String?
            
            if let keyString = input as? String {
                key = keyString // Input direto da chave como string
            } else if let params = input as? [String: Any] {
                // Input como dicionário { "key": ... }
                key = DSLExpression.shared.evaluate(params["key"], context) as? String
            } else {
                print("⚠️ Operator 'Storage.get': Invalid input type. Expected String or { \"key\": \"string\" }.")
                return nil
            }
            
            guard let finalKey = key else {
                print("⚠️ Operator 'Storage.get': Could not resolve key from input: \(String(describing: input))")
                return nil
            }
            
            return StorageHelper.get(key: finalKey)
        }
        
        // Adicionar outros operadores de storage aqui se necessário
    }
}
