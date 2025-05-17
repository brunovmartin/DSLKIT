package com.example.ComposeDSL

import org.json.JSONArray
import org.json.JSONObject

object DSLExpression {
    fun evaluate(expr: Any?, context: DSLContext): Any? {
        when (expr) {
            null -> return null
            is Map<*, *> -> {
                if (expr.size == 1 && expr.containsKey("var")) {
                    val path = expr["var"] as? String
                    return path?.let { resolvePath(it, context) }
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
        return value
    }
}
