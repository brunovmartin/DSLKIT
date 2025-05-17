package com.example.composedsl.commands

import com.example.composedsl.core.DSLCommandRegistry
import com.example.composedsl.core.DSLContext
import com.example.composedsl.core.DSLExpression
import com.example.composedsl.core.DSLInterpreter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

object HttpRequestCommand {
    fun registerAll() {
        DSLCommandRegistry.register("HttpRequest.request") { params, ctx ->
            val map = params as? Map<*, *> ?: return@register
            val urlStr = DSLExpression.evaluate(map["url"], ctx)?.toString() ?: return@register
            val method = (DSLExpression.evaluate(map["method"], ctx)?.toString() ?: "GET").uppercase()
            val varName = map["var"] as? String
            val onSuccess = map["onSuccess"]
            val onError = map["onError"]
            val onFinally = map["onFinally"]
            val headers = DSLExpression.evaluate(map["headers"], ctx) as? Map<*, *>
            val body = DSLExpression.evaluate(map["body"], ctx)

            CoroutineScope(Dispatchers.IO).launch {
                var success: Any? = null
                var error: Map<String, Any?>? = null
                try {
                    val url = URL(urlStr)
                    val conn = url.openConnection() as HttpURLConnection
                    conn.requestMethod = method
                    headers?.forEach { (k, v) -> conn.addRequestProperty(k.toString(), v.toString()) }
                    if (body != null && method != "GET") {
                        conn.doOutput = true
                        conn.outputStream.use { it.write(body.toString().toByteArray()) }
                    }
                    val code = conn.responseCode
                    val data = conn.inputStream.bufferedReader().use { it.readText() }
                    if (code in 200..299) {
                        success = try { JSONObject(data).toMap() } catch (_: Exception) { data }
                    } else {
                        error = mapOf("message" to "HTTP $code", "responseBody" to data)
                    }
                } catch (e: Exception) {
                    error = mapOf("message" to e.localizedMessage)
                }
                withContext(Dispatchers.Main) {
                    if (error != null) {
                        val errVar = "_httpRequestError"
                        val prev = ctx[errVar]
                        ctx[errVar] = error
                        onError?.let { DSLInterpreter.shared.handleEvent(it, ctx) }
                        if (prev != null) ctx[errVar] = prev else ctx.storage.remove(errVar)
                    } else {
                        if (varName != null) ctx[varName] = success
                        onSuccess?.let { DSLInterpreter.shared.handleEvent(it, ctx) }
                    }
                    onFinally?.let { DSLInterpreter.shared.handleEvent(it, ctx) }
                }
            }
        }
    }
}

private fun JSONObject.toMap(): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>()
    keys().forEach { key ->
        result[key] = when (val value = get(key)) {
            is JSONObject -> value.toMap()
            else -> value
        }
    }
    return result
}
