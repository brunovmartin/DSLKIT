import Foundation

/// Helper struct para interagir com UserDefaults (Storage) a partir da DSL.
struct StorageHelper {

    /// Salva um valor no UserDefaults associado a uma chave.
    /// - Parameters:
    ///   - key: A chave (String) para identificar o valor.
    ///   - value: O valor a ser salvo. Deve ser um tipo compatível com PropertyList (String, Int, Double, Bool, Data, Date, Array/Dict destes).
    static func set(key: String, value: Any?) {
        UserDefaults.standard.set(value, forKey: key)
        // print("--- DEBUG: StorageHelper.set - Key: \(key), Value: \(String(describing: value))")
    }

    /// Recupera um valor do UserDefaults usando uma chave.
    /// - Parameter key: A chave (String) do valor a ser recuperado.
    /// - Returns: O valor associado à chave, ou nil se não existir.
    static func get(key: String) -> Any? {
        let value = UserDefaults.standard.object(forKey: key)
        // print("--- DEBUG: StorageHelper.get - Key: \(key), Fetched Value: \(String(describing: value))")
        return value
    }
} 