package com.example.composedsl.core

import com.example.composedsl.operators.DSLOperatorRegistry
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

object DSLExpression {
    private const val TAG = "DSLExpression"
    fun evaluate(expr: Any?, context: DSLContext): Any? {
        when (expr) {
            null -> return null
            is Map<*, *> -> {
                if (expr.size == 1 && expr.containsKey("var")) {
                    val path = expr["var"] as? String
                    return path?.let {
                        val result = resolvePath(it, context)
                        Log.d(TAG, "resolvePath($it) -> $result")
                        result
                    }
                }
                val opName = expr.keys.firstOrNull() as? String
                val input = expr[opName]
                if (opName != null && DSLOperatorRegistry.isRegistered(opName)) {
                    val evaluatedInput = if (input is List<*>) {
                        input.map { evaluate(it, context) }
                    } else {
                        evaluate(input, context)
                    }
                    return DSLOperatorRegistry.evaluate(opName, evaluatedInput, context)
                }
                val result = mutableMapOf<String, Any?>()
                expr.forEach { (k, v) -> result[k as String] = evaluate(v, context) }
                return result
            }
            is List<*> -> return expr.map { evaluate(it, context) }
            is JSONArray -> {
                return (0 until expr.length()).map { evaluate(expr.get(it), context) }
            }
            is JSONObject -> {
                val map = mutableMapOf<String, Any?>()
                expr.keys().forEach { key -> map[key] = evaluate(expr.get(key), context) }
                return evaluate(map, context)
            }
            else -> return expr
        }
    }

    private fun resolvePath(path: String, context: DSLContext): Any? {
        Log.d(TAG, "Resolving path: $path")
        val parts = path.split(".")
        if (parts.isEmpty()) return null

        var value: Any? = resolvePart(parts.first(), context)
        for (part in parts.drop(1)) {
            value = when (value) {
                is Map<*, *> -> {
                    val key = part.substringBefore("[")
                    var v = value[key]
                    if (part.contains("[")) {
                        val indexToken = part.substringAfter("[").removeSuffix("]")
                        v = extractIndex(v, indexToken, context)
                    }
                    v
                }
                is List<*> -> {
                    val indexToken = part.removeSuffix("]").substringAfter("[")
                    extractIndex(value, indexToken, context)
                }
                else -> null
            }
        }
        Log.d(TAG, "Resolved '$path' -> $value")
        return value
    }

    private fun resolvePart(part: String, context: DSLContext): Any? {
        val key = part.substringBefore("[")
        var value: Any? = context[key]
        if (part.contains("[")) {
            val indexToken = part.substringAfter("[").removeSuffix("]")
            value = extractIndex(value, indexToken, context)
        }
        return value
    }

    private fun extractIndex(value: Any?, token: String, context: DSLContext): Any? {
        val list = value as? List<*> ?: return null
        val index = when (token) {
            "currentItemIndex" -> context.currentIndex
            else -> token.toIntOrNull()
        }
        return if (index != null && index in list.indices) list[index] else null
    }
}
