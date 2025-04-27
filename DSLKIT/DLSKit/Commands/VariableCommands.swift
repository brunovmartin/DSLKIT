import Foundation

public class VariableCommands {
    
    private static var pathComponentCache: [String: [Any]] = [:]
    
    public static func registerAll() {
        // Comando 'set'
        DSLCommandRegistry.shared.register("set") { payload, context in
            guard
                let setData = payload as? [String: Any],
                let key = setData["var"] as? String,
                let valueExpr = setData["value"]
            else {
                //print("⚠️ Comando 'set' inválido: payload incompleto ou mal formatado. Payload: \(String(describing: payload))")
                return
            }
            let resolvedValue = DSLExpression.shared.evaluate(valueExpr, context) ?? NSNull()
            //print("--- DEBUG: VariableCommands 'set' - Key: \(key), Resolved Value: \(String(describing: resolvedValue))")
            context.set(key, to: resolvedValue)
        }

        // Comando 'setAtPath'
        DSLCommandRegistry.shared.register("setAtPath") { payload, context in
            guard
                let params = payload as? [String: Any],
                let targetPath = params["path"] as? String,
                let valueExpr = params["value"]
            else {
                //print("⚠️ Comando 'setAtPath' inválido. Payload: \(String(describing: payload))")
                return
            }

            let resolvedValue = DSLExpression.shared.evaluate(valueExpr, context) ?? NSNull()
            let components = Self.parsePathComponents(targetPath, context: context)

            guard !components.isEmpty, let baseVar = components[0] as? String else {
                //print("⚠️ 'setAtPath' - Path inválido ou não inicia com variável. Path: \(targetPath)")
                return
            }

            var currentMutableValue: Any
            if let existingValue = context.get(baseVar), !(existingValue is NSNull) {
                currentMutableValue = existingValue
            } else {
                // Inicializa se não existir
                if components.count > 1 {
                    if components[1] is String {
                        currentMutableValue = [String: Any]()
                    } else if components[1] is Int {
                        currentMutableValue = [Any]()
                    } else {
                        //print("⚠️ 'setAtPath' - Base '\(baseVar)' not found, cannot initialize.")
                        return
                    }
                    //print("--- DEBUG: 'setAtPath' - Initialized base var '\(baseVar)'.")
                } else if components.count == 1 {
                    // Apenas a variável base
                    //print("--- DEBUG: 'setAtPath' - Base '\(baseVar)' not found, setting directly.")
                    context.set(baseVar, to: resolvedValue)
                    return
                } else {
                    return
                }
            }

            // Corrige o typo '¤tMutableValue' -> '&currentMutableValue'
            if Self.modifyValueAtPath(&currentMutableValue, pathComponents: Array(components.dropFirst()), newValue: resolvedValue) {
                context.set(baseVar, to: currentMutableValue)
                //print("--- DEBUG: 'setAtPath' - Path write successful for: \(targetPath)")
            } else {
                //print("⚠️ 'setAtPath' - Path write failed for: \(targetPath)")
            }
        }
    } // Fim registerAll

    // --- Funções Auxiliares Estáticas ---

    public static func parsePathComponents(_ path: String, context: DSLContext) -> [Any] {
        // --- START MODIFICATION ---
        // Check cache first
        // cacheLock.lock() // Uncomment if using lock
        if let cachedComponents = pathComponentCache[path] {
            //print("--- Path Cache HIT for: \(path)")
            // cacheLock.unlock() // Uncomment if using lock
            return cachedComponents
        }
        //print("--- Path Cache MISS for: \(path)")
        // cacheLock.unlock() // Uncomment if using lock
        // --- END MODIFICATION ---


        // --- Existing parsing logic ---
        var components: [Any] = []
        var currentPath = path
        let scanner = Scanner(string: path)
        scanner.charactersToBeSkipped = nil

        guard let baseVar = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: ".[")) else {
            if path.isEmpty { return [] }
            return []
        }
        components.append(baseVar)
        currentPath = String(path.dropFirst(scanner.scanLocation))

        while !currentPath.isEmpty {
             if currentPath.hasPrefix(".") {
                currentPath.removeFirst()
                let keyScanner = Scanner(string: currentPath)
                keyScanner.charactersToBeSkipped = nil
                if let key = keyScanner.scanUpToCharacters(from: CharacterSet(charactersIn: ".[")) {
                    components.append(key)
                    currentPath = String(currentPath.dropFirst(keyScanner.scanLocation))
                } else {
                    if !currentPath.isEmpty { components.append(currentPath) }
                    currentPath = ""
                }
            } else if currentPath.hasPrefix("[") {
                currentPath.removeFirst()
                let indexScanner = Scanner(string: currentPath)
                indexScanner.charactersToBeSkipped = nil
                guard let indexStr = indexScanner.scanUpToCharacters(from: CharacterSet(charactersIn: "]")) else {
                   return []
                }
                // --- Potential Micro-Optimization: Check if indexStr is already an Int before converting ---
                // Swift's Int initializer is efficient, but this avoids creating the Scanner if not needed.
                // However, the current approach handles integer literals correctly.
                guard let indexInt = Int(indexStr) else {
                   return []
                }
                components.append(indexInt)
                currentPath = String(currentPath.dropFirst(indexScanner.scanLocation))
                guard currentPath.hasPrefix("]") else {
                   return []
                }
                currentPath.removeFirst()
            } else {
                return []
            }
        }
        // --- End Existing Parsing ---

        // --- START MODIFICATION ---
        // Store result in cache before returning
        // cacheLock.lock() // Uncomment if using lock
        pathComponentCache[path] = components
        // cacheLock.unlock() // Uncomment if using lock
        //print("--- Parsed Path for \(path): \(components)")
        // --- END MODIFICATION ---

        return components
    }

    public static func modifyValueAtPath(_ data: inout Any, pathComponents: [Any], newValue: Any) -> Bool {
        guard !pathComponents.isEmpty else {
            data = newValue
            return true
        }

        var nextComponents = pathComponents
        let currentKeyOrIndex = nextComponents.removeFirst()

        if let key = currentKeyOrIndex as? String {
            var dict = (data as? [String: Any]) ?? [:]
            // Use 'Any' em vez de 'Any?' para evitar optional
            var subValue: Any = dict[key] ?? NSNull()

            if (subValue is NSNull) && !nextComponents.isEmpty {
                if nextComponents.first is String {
                    subValue = [String: Any]()
                } else if nextComponents.first is Int {
                    subValue = [Any]()
                } else {
                    return false
                }
            }

            if modifyValueAtPath(&subValue, pathComponents: nextComponents, newValue: newValue) {
                dict[key] = subValue
                data = dict
                return true
            } else {
                return false
            }
        } else if let index = currentKeyOrIndex as? Int {
            guard var array = data as? [Any] else { return false }
            while index >= array.count {
                array.append(NSNull())
            }
            var subValue: Any = array[index]

            if (subValue is NSNull) && !nextComponents.isEmpty {
                if nextComponents.first is String {
                    subValue = [String: Any]()
                } else if nextComponents.first is Int {
                    subValue = [Any]()
                } else {
                    return false
                }
            }

            if modifyValueAtPath(&subValue, pathComponents: nextComponents, newValue: newValue) {
                array[index] = subValue
                data = array
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}
