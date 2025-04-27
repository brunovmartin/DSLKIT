import Foundation

public class VariableCommands {
    
    private static var pathComponentCache: [String: [Any]] = [:]
    
    public static func registerAll() {
        // Comando 'set' (Modificado para usar lógica de path)
        DSLCommandRegistry.shared.register("set") { payload, context in
            guard
                let setData = payload as? [String: Any],
                let targetPath = setData["var"] as? String, // Renomear 'key' para 'targetPath'
                let valueExpr = setData["value"]
            else {
                print("⚠️ Comando 'set' inválido: payload incompleto ou mal formatado. Payload: \(String(describing: payload))")
                return
            }
            let resolvedValue = DSLExpression.shared.evaluate(valueExpr, context) ?? NSNull()
            print("--- DEBUG: VariableCommands 'set' - Path: \(targetPath), Resolved Value: \(String(describing: resolvedValue))")
            
            // --- Lógica Adaptada de setAtPath --- 
            let components = Self.parsePathComponents(targetPath, context: context)
            
            guard !components.isEmpty, let baseVar = components[0] as? String else {
                print("⚠️ 'set' - Path inválido ou não inicia com variável. Path: \(targetPath)")
                return
            }
            
            // Obter o valor base atual ou inicializar se necessário
            var currentMutableValue: Any
            if let existingValue = context.get(baseVar), !(existingValue is NSNull) {
                 currentMutableValue = existingValue
            } else {
                 // Inicializa se não existir e o path for mais profundo
                 if components.count > 1 {
                     if components[1] is String {
                         currentMutableValue = [String: Any]()
                         print("--- DEBUG: 'set' - Initialized base dictionary '\(baseVar)'.")
                     } else if components[1] is Int {
                         currentMutableValue = [Any]() // Embora set em array por string não faça sentido aqui
                         print("--- DEBUG: 'set' - Initialized base array '\(baseVar)'.")
                     } else {
                         print("⚠️ 'set' - Base '\(baseVar)' not found, cannot initialize for path component: \(components[1]).")
                         return
                     }
                 } else if components.count == 1 { // Apenas a variável base
                      print("--- DEBUG: 'set' - Setting base variable '\(baseVar)' directly.")
                      // Notificar ANTES da mudança para @Published funcionar
                      context.objectWillChange.send()
                      context.set(baseVar, to: resolvedValue) 
                      return
                 } else { // Path vazio, já tratado acima
                      return
                 }
             }
             
             // Chamar a função auxiliar para modificar o valor no caminho restante
             print("--- DEBUG: 'set' - Attempting to modify path for base '\(baseVar)'. Components: \(Array(components.dropFirst()))")
             // Notificar ANTES da mudança para @Published funcionar
             context.objectWillChange.send()
             if Self.modifyValueAtPath(&currentMutableValue, pathComponents: Array(components.dropFirst()), newValue: resolvedValue) {
                 // Atualizar o valor base no contexto com a estrutura modificada
                 context.set(baseVar, to: currentMutableValue)
                 print("--- DEBUG: 'set' - Path write successful for: \(targetPath)")
             } else {
                 print("⚠️ 'set' - Path write failed for: \(targetPath)")
                 // Opcional: Desfazer a notificação se a escrita falhar? Depende da granularidade desejada.
             }
            // Remover chamada antiga
            // context.set(key, to: resolvedValue)
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
        if let cachedComponents = pathComponentCache[path] { return cachedComponents }

        var components: [Any] = []
        let scanner = Scanner(string: path)
        scanner.charactersToBeSkipped = nil // Manter processamento de . e []

        // Lê a variável base
        guard let baseVar = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: ".[")) else {
             if path.isEmpty { return [] }
             if !path.contains(".") && !path.contains("[") {
                 components.append(path)
                 pathComponentCache[path] = components
                 return components
             }
             return []
        }
        components.append(baseVar)
        
        // Processa o resto do caminho usando APIs modernas
        while !scanner.isAtEnd {
            // Verifica o próximo caractere sem avançar
            guard let nextChar = scanner.string[scanner.currentIndex...].first else { break } 

            if nextChar == "." { // Acesso a propriedade via ponto
                scanner.currentIndex = scanner.string.index(after: scanner.currentIndex) // Avança o ponto
                guard !scanner.isAtEnd else { return [] } // Ponto não pode ser o último caractere
                
                let startScanIndex = scanner.currentIndex
                let key = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: ".["))
                 // Se scanUpToCharacters falhar mas ainda houver caracteres, pega o resto
                let finalKey = key ?? String(scanner.string[startScanIndex...])
                
                if !finalKey.isEmpty { components.append(finalKey) }
                 else { return [] } // Chave vazia após ponto é inválido

            } else if nextChar == "[" { // Acesso a índice/chave via colchetes
                scanner.currentIndex = scanner.string.index(after: scanner.currentIndex) // Avança o colchete [ 
                guard !scanner.isAtEnd else { return [] } // Não pode terminar após [ 

                guard let content = scanner.scanUpToString("]") else { // Lê até o ]
                    return [] // Não encontrou ]
                }
                 scanner.currentIndex = scanner.string.index(after: scanner.currentIndex) // Avança o ]

                if let indexInt = Int(content) {
                    components.append(indexInt)
                } else {
                    components.append("VAR::" + content) // Chave dinâmica
                }
            } else {
                // Caractere inesperado
                return []
            }
        }

        pathComponentCache[path] = components
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
