package com.example.composedsl.core

import com.example.composedsl.operators.DSLOperatorRegistry
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

object DSLExpression {
    private const val TAG = "DSLExpression"
    private const val INDEX_PLACEHOLDER = "[currentItemIndex]"

    private fun resolvePlaceholders(data: Any?, context: DSLContext): Any? {
        val idx = context.currentIndex ?: return data
        if (data == null) return null
        return when (data) {
            is Map<*, *> -> {
                val result = mutableMapOf<String, Any?>()
                data.forEach { (k, v) ->
                    val key = k as String
                    if (key == "var" && v is String && v.contains(INDEX_PLACEHOLDER)) {
                        result[key] = v.replace(INDEX_PLACEHOLDER, "[$idx]")
                    } else {
                        result[key] = resolvePlaceholders(v, context)
                    }
                }
                result
            }
            is List<*> -> data.map { resolvePlaceholders(it, context) }
            is String -> data.replace(INDEX_PLACEHOLDER, "[$idx]")
            is JSONObject -> resolvePlaceholders(data.toMap(), context)
            is JSONArray -> (0 until data.length()).map { resolvePlaceholders(data.get(it), context) }
            else -> data
        }
    }
    fun evaluate(expr: Any?, context: DSLContext): Any? {
        val resolvedExpr = resolvePlaceholders(expr, context)
        when (resolvedExpr) {
            null -> return null
            is Map<*, *> -> {
                if (resolvedExpr.size == 1 && resolvedExpr.containsKey("var")) {
                    val path = resolvedExpr["var"] as? String
                    return path?.let {
                        val result = resolvePath(it, context)
                        Log.d(TAG, "resolvePath($it) -> $result")
                        result
                    }
                }
                val opName = resolvedExpr.keys.firstOrNull() as? String
                val input = resolvedExpr[opName]
                if (opName != null && DSLOperatorRegistry.isRegistered(opName)) {
                    val evaluatedInput = if (input is List<*>) {
                        input.map { evaluate(it, context) }
                    } else {
                        evaluate(input, context)
                    }
                    return DSLOperatorRegistry.evaluate(opName, evaluatedInput, context)
                }
                val result = mutableMapOf<String, Any?>()
                resolvedExpr.forEach { (k, v) -> result[k as String] = evaluate(v, context) }
                return result
            }
            is List<*> -> return resolvedExpr.map { evaluate(it, context) }
            is JSONArray -> {
                return (0 until resolvedExpr.length()).map { evaluate(resolvedExpr.get(it), context) }
            }
            is JSONObject -> {
                val map = mutableMapOf<String, Any?>()
                resolvedExpr.keys().forEach { key -> map[key] = evaluate(resolvedExpr.get(key), context) }
                return evaluate(map, context)
            }
            else -> return resolvedExpr
        }
    }

    private fun resolvePath(path: String, context: DSLContext): Any? {
        Log.d(TAG, "Resolving path: $path")
        val parts = path.split(".")
        var value: Any? = context[parts.firstOrNull() ?: return null]
        for (part in parts.drop(1)) {
            value = when (value) {
                is Map<*, *> -> value[part]
                is List<*> -> {
                    val index = part.removeSuffix("]").substringAfter("[").toIntOrNull()
                    if (index != null && value.size > index) value[index] else null
                }
                else -> return null
            }
        }
        Log.d(TAG, "Resolved '$path' -> $value")
        return value
    }
}
