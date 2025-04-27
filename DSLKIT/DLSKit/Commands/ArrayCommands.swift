import Foundation

public class ArrayCommands {
    public static func registerAll() {
        DSLCommandRegistry.shared.register("append") { payload, context in
            guard let params = payload as? [String: Any],
                  let key = params["var"] as? String,
                  let valueExpr = params["value"]
            else {
                //print("⚠️ Comando 'append' inválido: payload incompleto ou mal formatado. Payload: \(String(describing: payload))")
                return
            }

            let valueToAdd = DSLExpression.shared.evaluate(valueExpr, context)

            guard let valueToAdd = valueToAdd else {
                 //print("⚠️ Comando 'append': valor a ser adicionado resultou em nil após avaliação.")
                 return
            }

            var currentArray: [Any] = []
            if let existingArray = context.get(key) as? [Any] {
                currentArray = existingArray
            } else if context.get(key) != nil {
                //print("⚠️ Comando 'append': Variável '\(key)' existe mas não é um array.")
                return
            }

            currentArray.append(valueToAdd)
            //print("--- DEBUG: ArrayCommands 'append' - Appending to '\(key)', New array count: \(currentArray.count)")

            context.set(key, to: currentArray)
        }
        
        DSLOperatorRegistry.shared.register("Array.count") { input, context in
            // 1. Avalia a expressão passada para o operador (ex: pode ser {"var": "items"})
            //    Isso garante que se o input for {"var": "nomeArray"}, ele resolva para o array real.
            let evaluatedInput = DSLExpression.shared.evaluate(input, context)

            // 2. Verifica se o resultado da avaliação é um Array
            guard let array = evaluatedInput as? [Any] else {
//                print("⚠️ Array.count: Input não resultou em um array após avaliação. Input: \(String(describing: input)), Evaluated: \(String(describing: evaluatedInput))")
                return nil // Ou talvez 0, dependendo de como quer tratar erros
            }

            // 3. Retorna a contagem do array (como Int)
//            print("--- DEBUG: Array.count - Array evaluated, count: \(array.count)")
            return array.count
        }
        
    }
}
