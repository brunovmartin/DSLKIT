import Foundation

public class ArrayCommands {
    public static func registerAll() {
        DSLCommandRegistry.shared.register("Array.append") { payload, context in
            guard let params = payload as? [String: Any],
                  let targetPath = params["var"] as? String,
                  let valueExpr = params["value"]
            else {
                logDebug("⚠️ Comando 'append' inválido: payload incompleto ou mal formatado. Payload: \(String(describing: payload))")
                return
            }

            let valueToAdd = DSLExpression.shared.evaluate(valueExpr, context)

            let components = VariableCommands.parsePathComponents(targetPath, context: context)

            guard !components.isEmpty, let baseVar = components[0] as? String else {
                logDebug("⚠️ Comando 'append': Path inválido ou não inicia com variável. Path: \(targetPath)")
                return
            }

            var mutableValue: Any
            if let existingValue = context.get(baseVar), !(existingValue is NSNull) {
                 mutableValue = existingValue
            } else {
                if components.count > 1 {
                    if components[1] is String {
                        logDebug("--- DEBUG: 'append' - Initializing base dictionary '\(baseVar)' for path.")
                        mutableValue = [String: Any]()
                    } else if components[1] is Int {
                        logDebug("--- DEBUG: 'append' - Initializing base array '\(baseVar)' for path.")
                        mutableValue = [Any]()
                    } else {
                        logDebug("⚠️ 'append' - Base var '\(baseVar)' not found, cannot determine initial type from path component: \(components[1]).")
                        return
                    }
                } else if components.count == 1 {
                    logDebug("--- DEBUG: 'append' - Initializing base variable '\(baseVar)' as array.")
                    mutableValue = [Any]()
                } else {
                     logDebug("⚠️ 'append' - Cannot handle empty path.")
                     return
                }
            }

            context.objectWillChange.send()

            let pathRemainder = Array(components.dropFirst())
            if appendAtPath(&mutableValue, pathComponents: pathRemainder, valueToAppend: valueToAdd ?? NSNull()) {
                context.set(baseVar, to: mutableValue)
                logDebug("--- DEBUG: 'append' - Path append successful for: \(targetPath)")
            } else {
                logDebug("⚠️ 'append' - Path append failed for: \(targetPath)")
            }
        }
        
        DSLOperatorRegistry.shared.register("Array.count") { input, context in
            let evaluatedInput = DSLExpression.shared.evaluate(input, context)
            guard let array = evaluatedInput as? [Any] else {
                return nil
            }
            return array.count
        }
        
    }

    private static func appendAtPath(_ data: inout Any, pathComponents: [Any], valueToAppend: Any) -> Bool {
        guard !pathComponents.isEmpty else {
            guard var array = data as? [Any] else {
                if data is NSNull { 
                    logDebug("--- DEBUG: appendAtPath - Initializing array at target path.")
                    var newArray = [Any]()
                    newArray.append(valueToAppend)
                    data = newArray
                    return true
                }
                logDebug("⚠️ appendAtPath: Target is not an array and not nil/NSNull. Cannot append. Data: \(data)")
                return false
            }
            array.append(valueToAppend)
            data = array
            return true
        }

        var nextComponents = pathComponents
        let currentKeyOrIndex = nextComponents.removeFirst()

        if let key = currentKeyOrIndex as? String {
            guard var dict = data as? [String: Any] else {
                if data is NSNull { 
                     logDebug("--- DEBUG: appendAtPath - Initializing intermediate dictionary for key '\(key)'.")
                     var newDictAsAny: Any = [String: Any]()
                     if appendAtPath(&newDictAsAny, pathComponents: nextComponents, valueToAppend: valueToAppend) {
                         data = newDictAsAny
                         return true
                     } else {
                         return false
                     }
                 } else {
                     logDebug("⚠️ appendAtPath: Trying to access key '\(key)' on non-dictionary. Data: \(data)")
                     return false
                 }
            }
            var subValue: Any = dict[key] ?? NSNull()

            if appendAtPath(&subValue, pathComponents: nextComponents, valueToAppend: valueToAppend) {
                dict[key] = subValue
                data = dict
                return true
            } else {
                return false
            }
        } else if let index = currentKeyOrIndex as? Int {
            guard var array = data as? [Any] else {
                 if data is NSNull { 
                     logDebug("--- DEBUG: appendAtPath - Initializing intermediate array for index \(index). Note: Will extend with NSNull if needed.")
                     var newArrayAsAny: Any = [Any]()
                     if var tempArray = newArrayAsAny as? [Any] {
                         while index >= tempArray.count {
                             tempArray.append(NSNull())
                         }
                         newArrayAsAny = tempArray
                     }
                     if appendAtPath(&newArrayAsAny, pathComponents: nextComponents, valueToAppend: valueToAppend) {
                         data = newArrayAsAny
                         return true
                     } else {
                         return false
                     }
                 } else {
                     logDebug("⚠️ appendAtPath: Trying to access index \(index) on non-array. Data: \(data)")
                     return false
                 }
            }

            while index >= array.count {
                array.append(NSNull())
            }
            var subValue: Any = array[index]

            if appendAtPath(&subValue, pathComponents: nextComponents, valueToAppend: valueToAppend) {
                array[index] = subValue
                data = array
                return true
            } else {
                return false
            }
        } else {
            logDebug("⚠️ appendAtPath: Invalid path component type: \(currentKeyOrIndex)")
            return false
        }
    }
}
