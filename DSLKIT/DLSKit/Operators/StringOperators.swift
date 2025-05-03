import Foundation

public class StringOperators {
    public static func registerAll() {

        // String.trim
        DSLOperatorRegistry.shared.register("String.trim") { input, _ in
            // Correção: Certifique-se de que o input seja avaliado ANTES se for uma expressão
            // Mas aqui, vamos assumir que o evaluate já fez isso antes de chamar o operador.
             guard let str = input as? String else { return nil } // Modificado para trabalhar com input direto
            return str.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // String.uppercase
        DSLOperatorRegistry.shared.register("String.uppercase") { input, _ in
            // Correção: Trabalhar com input direto
             guard let str = input as? String else { return nil }
            return str.uppercased()
        }

        // --- CORREÇÃO PRINCIPAL NO String.add ---
        DSLOperatorRegistry.shared.register("String.add") { input, context in // Manter context para consistência
            // Input é o array [Any?] JÁ AVALIADO pelo DSLExpression
            guard let items = input as? [Any?] else {
                //logDebug("⚠️ Operador String.add recebeu input inválido (não é um array [Any?]). Input: \(String(describing: input))")
                return nil
            }

            // Mapeia diretamente os items (já avaliados) para String, tratando nil/NSNull
            let strings = items.map { item -> String in
                if let item = item, !(item is NSNull) {
                     // Usa interpolação de string que funciona bem para tipos comuns
                    return "\(item)"
                } else {
                    // Converte nil ou NSNull para string vazia
                    return ""
                }
            }
            //logDebug("--- DEBUG: String.add - Items converted to strings: \(strings)") // Log atualizado

            // Junta as strings resultantes
            return strings.joined()
        }
        // --- FIM DA CORREÇÃO String.add ---

        // String.indexOf (já estava avaliando corretamente, mas podemos simplificar se o evaluate sempre acontece antes)
        DSLOperatorRegistry.shared.register("String.indexOf") { input, context in
            guard let dict = input as? [String: Any],
                  // Assumindo que DSLExpression avaliou o dict ANTES de chamar o operador
                  // Se dict["source"] ou dict["search"] fossem {"var":...}, eles já teriam sido resolvidos.
                  let text = dict["source"] as? String, // Pega o valor direto
                  let search = dict["search"] as? String else { // Pega o valor direto
                //logDebug("⚠️ Operador String.indexOf recebeu input inválido ou não avaliado. Input: \(String(describing: input))")
                return nil
            }
            if let range = text.range(of: search) {
                return text.distance(from: text.startIndex, to: range.lowerBound)
            }
            return -1
        }
        
        
        // Add this inside StringOperators.registerAll()

        DSLOperatorRegistry.shared.register("String.substring") { input, context in
            guard let args = input as? [Any], args.count == 3 else {
                //logDebug("⚠️ String.substring: Requires array input with 3 arguments [stringExpr, startIndex, length]. Input: \(String(describing: input))")
                return nil
            }

            // Evaluate the first argument, which should be the source string or expression
            let sourceStringValue = DSLExpression.shared.evaluate(args[0], context)
            guard let sourceString = sourceStringValue as? String else {
                //logDebug("⚠️ String.substring: First argument did not evaluate to a String. Evaluated: \(String(describing: sourceStringValue))")
                return nil
            }

            // Evaluate start index and length (expecting Ints directly or expressions)
            let startIndexValue = DSLExpression.shared.evaluate(args[1], context)
            let lengthValue = DSLExpression.shared.evaluate(args[2], context)

            guard let startIndex = startIndexValue as? Int, let length = lengthValue as? Int else {
                //logDebug("⚠️ String.substring: Second (startIndex) or third (length) argument did not evaluate to Int. Start: \(String(describing: startIndexValue)), Length: \(String(describing: lengthValue))")
                return nil
            }

            guard startIndex >= 0, length >= 0, startIndex <= sourceString.count else {
                //logDebug("⚠️ String.substring: Invalid startIndex (\(startIndex)) or length (\(length)) for string '\(sourceString)'")
                return "" // Return empty string for invalid indices/length
            }

            let calculatedEndIndex = startIndex + length
            guard calculatedEndIndex <= sourceString.count else {
                //logDebug("⚠️ String.substring: Calculated endIndex (\(calculatedEndIndex)) is out of bounds for string '\(sourceString)'")
                 // Return substring up to the end if length goes beyond
                let start = sourceString.index(sourceString.startIndex, offsetBy: startIndex)
                return String(sourceString[start...])

            }

            let start = sourceString.index(sourceString.startIndex, offsetBy: startIndex)
            let end = sourceString.index(start, offsetBy: length)

            //logDebug("--- DEBUG: String.substring - Source: '\(sourceString)', StartIdx: \(startIndex), Len: \(length), Result: '\(String(sourceString[start..<end]))'")
            return String(sourceString[start..<end])
        }
        
    }
}
