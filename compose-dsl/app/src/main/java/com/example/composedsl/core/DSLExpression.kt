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
        var value: Any? = context
        for (part in parts) {
            if (value == null) return null
            val key = part.substringBefore("[")
            val indexToken = part.substringAfter("[", "").substringBefore("]", "")
            value = when (value) {
                is DSLContext -> value[key]
                is Map<*, *> -> value[key]
                else -> return null
            }
            if (indexToken.isNotEmpty()) {
                val index = when (indexToken) {
                    "currentItemIndex" -> context.currentIndex
                    else -> indexToken.toIntOrNull()
                }
                value = if (value is List<*> && index != null && index >= 0 && index < value.size) {
                    value[index]
                } else {
                    null
                }
            }
        }
        Log.d(TAG, "Resolved '$path' -> $value")
        return value
    }
}
