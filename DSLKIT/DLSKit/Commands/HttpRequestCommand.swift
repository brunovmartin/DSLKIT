import Foundation
import SwiftUI // Para usar DispatchQueue.main

public class HttpRequestCommand {
    public static func registerAll() {
        DSLCommandRegistry.shared.register("HttpRequest.request") { params, context in
            // 1. Validar e extrair parâmetros do 'params: Any?'
            guard let requestParams = params as? [String: Any],
                  let urlStringExpr = requestParams["url"] else {
                print("⚠️ Command 'httpRequest': Parâmetros inválidos. Requer pelo menos 'url'. Params: \(String(describing: params))")
                // REMOVIDO: Não executa finally se os parâmetros do comando estiverem errados
                // executeFinally(params: requestParams, context: context)
                return
            }

            // Avaliar a URL (pode ser uma string ou expressão)
            guard let urlString = DSLExpression.shared.evaluate(urlStringExpr, context) as? String,
                  let url = URL(string: urlString) else {
                print("⚠️ Command 'httpRequest': URL inválida ou falha ao avaliar expressão da URL. Expressão: \(urlStringExpr)")
                executeOnError(params: requestParams, errorDetails: ["message": "URL inválida", "urlExpr": String(describing: urlStringExpr)], context: context)
                executeFinally(params: requestParams, context: context)
                return
            }

            // Extrair outros parâmetros (com valores padrão)
            let method = (DSLExpression.shared.evaluate(requestParams["method"], context) as? String)?.uppercased() ?? "GET"
            let headersExpr = requestParams["headers"]
            let bodyExpr = requestParams["body"]
            let varName = requestParams["var"] as? String // Nome da variável não precisa ser avaliado
            let onSuccessAction = requestParams["onSuccess"] // Ação não avaliada aqui
            let onErrorAction = requestParams["onError"]     // Ação não avaliada aqui
            let onFinallyAction = requestParams["onFinally"] // Ação não avaliada aqui

            // 2. Construir URLRequest
            var request = URLRequest(url: url)
            request.httpMethod = method

            // Avaliar e adicionar Headers
            if let evaluatedHeaders = DSLExpression.shared.evaluate(headersExpr, context) as? [String: Any] {
                for (key, value) in evaluatedHeaders {
                    // Tenta converter valor para String, tratando Int, Double, etc.
                    request.addValue(String(describing: value), forHTTPHeaderField: key)
                }
            }

            // Avaliar, serializar e adicionar Body (Exemplo: Assume JSON se for Dicionário/Array)
            if let evaluatedBody = DSLExpression.shared.evaluate(bodyExpr, context) {
                if JSONSerialization.isValidJSONObject(evaluatedBody) {
                    if let jsonData = try? JSONSerialization.data(withJSONObject: evaluatedBody) {
                        request.httpBody = jsonData
                        // Adicionar Content-Type se não estiver nos headers customizados
                        if request.value(forHTTPHeaderField: "Content-Type") == nil {
                            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        }
                    } else {
                        print("⚠️ Command 'httpRequest': Falha ao serializar body JSON. Body: \(evaluatedBody)")
                        executeOnError(params: requestParams, errorDetails: ["message": "Falha ao serializar body JSON"], context: context)
                        executeFinally(params: requestParams, context: context)
                        return
                    }
                } else if let bodyString = evaluatedBody as? String {
                    request.httpBody = bodyString.data(using: .utf8)
                     // Adicionar Content-Type se não estiver nos headers customizados (ex: text/plain)
                    if request.value(forHTTPHeaderField: "Content-Type") == nil {
                         request.addValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    }
                } else {
                     print("⚠️ Command 'httpRequest': Tipo de body não suportado (precisa ser Dicionário/Array JSON ou String). Body: \(evaluatedBody)")
                    executeOnError(params: requestParams, errorDetails: ["message": "Tipo de body não suportado"], context: context)
                    executeFinally(params: requestParams, context: context)
                    return
                }
            }


            // 3. Executar a Requisição Assíncrona
            print("--- DEBUG: HttpRequest - Executing \(method) to \(url)")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // Garantir execução na Main Thread para atualizações de UI/Contexto e execução de comandos
                DispatchQueue.main.async {
                    var errorDetails: [String: Any]? = nil
                    var successData: Any? = nil

                    // Verificar Erro de Rede
                    if let networkError = error {
                        print("--- DEBUG: HttpRequest - Network Error: \(networkError.localizedDescription)")
                        errorDetails = [
                            "message": "Erro de rede",
                            "description": networkError.localizedDescription
                        ]
                    } else if let httpResponse = response as? HTTPURLResponse {
                        print("--- DEBUG: HttpRequest - Received Status Code: \(httpResponse.statusCode)")
                        // Verificar Status Code (Considerar 2xx como sucesso)
                        if !(200...299).contains(httpResponse.statusCode) {
                            errorDetails = [
                                "message": "Erro HTTP",
                                "statusCode": httpResponse.statusCode,
                                "responseHeaders": httpResponse.allHeaderFields
                            ]
                            // Tentar ler corpo da resposta de erro (se houver)
                            if let errorData = data, let errorBody = String(data: errorData, encoding: .utf8) {
                                errorDetails?["responseBody"] = errorBody
                            }
                        } else {
                            // Sucesso! Processar dados
                            if let responseData = data {
                                // Tentar decodificar JSON por padrão
                                if let jsonObject = try? JSONSerialization.jsonObject(with: responseData, options: []) {
                                    successData = jsonObject
                                    print("--- DEBUG: HttpRequest - Success. Decoded JSON Response.")
                                } else if let stringObject = String(data: responseData, encoding: .utf8) {
                                    // Se não for JSON, guardar como String
                                    successData = stringObject
                                    print("--- DEBUG: HttpRequest - Success. Received String Response.")
                                } else {
                                    successData = responseData // Guardar como Data se não for decodificável
                                    print("--- DEBUG: HttpRequest - Success. Received Raw Data Response.")
                                }
                            } else {
                                // Resposta 2xx sem corpo (ex: 204 No Content)
                                successData = NSNull() // Representar ausência de dados
                                 print("--- DEBUG: HttpRequest - Success. No Content.")
                            }
                        }
                    } else {
                        // Caso inesperado (sem erro, mas sem resposta HTTP)
                        errorDetails = ["message": "Resposta inválida recebida"]
                        print("--- DEBUG: HttpRequest - Invalid Response (not HTTPURLResponse)")
                    }

                    // 4. Chamar Callbacks (onError ou onSuccess) e Armazenar Variável
                    if let details = errorDetails {
                         print("--- DEBUG: HttpRequest - Executing onError...")
                        executeOnError(params: requestParams, errorDetails: details, context: context)
                    } else {
                        // Armazenar na variável ANTES de executar onSuccess
                        if let varName = varName, let dataToStore = successData {
                            print("--- DEBUG: HttpRequest - Storing response in context var '\(varName)'")
                            context.set(varName, to: dataToStore)
                        } else if let varName = varName {
                            // Se não houve dados mas var foi pedida, setar para null
                            print("--- DEBUG: HttpRequest - Setting context var '\(varName)' to null (no success data)")
                            context.set(varName, to: NSNull())
                        }
                         print("--- DEBUG: HttpRequest - Executing onSuccess...")
                        executeOnSuccess(params: requestParams, context: context)
                    }

                    // 5. Chamar onFinally
                    print("--- DEBUG: HttpRequest - Executing onFinally...")
                    executeFinally(params: requestParams, context: context)
                } // Fim do DispatchQueue.main.async
            }
            task.resume()
        } // Fim do register
    }

    // Helper para executar onSuccess
    private static func executeOnSuccess(params: [String: Any], context: DSLContext) {
         if let successAction = params["onSuccess"] {
             DSLInterpreter.shared.handleEvent(successAction, context: context)
         }
    }

    // Helper para executar onError
    private static func executeOnError(params: [String: Any], errorDetails: [String: Any], context: DSLContext) {
         if let errorAction = params["onError"] {
             // Opção 1: variável temporária no contexto.
             let errorVarName = "_httpRequestError" // Usar um nome menos genérico
             let originalErrorValue = context.get(errorVarName)
             context.set(errorVarName, to: errorDetails)
             print("--- DEBUG: HttpRequest Error - Setting \(errorVarName): \(errorDetails)")
             DSLInterpreter.shared.handleEvent(errorAction, context: context)
             context.set(errorVarName, to: originalErrorValue ?? NSNull()) // Limpar após uso
              print("--- DEBUG: HttpRequest Error - Cleared \(errorVarName)")
         }
    }

     // Helper para executar onFinally
     private static func executeFinally(params: [String: Any], context: DSLContext) {
         if let finallyAction = params["onFinally"] {
             DSLInterpreter.shared.handleEvent(finallyAction, context: context)
         }
     }
} 