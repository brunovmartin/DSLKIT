package com.example.composedsl.commands

import com.example.composedsl.core.*

object DSLCommandRegistry {
    private val registry = mutableMapOf<String, (Any?, DSLContext) -> Unit>()

    fun register(name: String, fn: (Any?, DSLContext) -> Unit) {
        registry[name] = fn
    }

    fun execute(command: Map<String, Any?>, context: DSLContext) {
        val name = command.keys.firstOrNull() ?: return
        val params = command[name]
        registry[name]?.invoke(params, context)
    }

    fun registerDefaults() {
        register("set") { params, ctx ->
            val map = params as? Map<*, *> ?: return@register
            val varPath = map["var"] as? String ?: return@register
            val valueExpr = map["value"]
            ctx[varPath] = DSLExpression.evaluate(valueExpr, ctx)
        }

        register("print") { params, ctx ->
            println("DSL print >>> ${DSLExpression.evaluate(params, ctx)}")
        }

        register("navigate") { params, ctx ->
            val screenId = when (params) {
                is String -> params
                is Map<*, *> -> DSLExpression.evaluate(params["screenId"], ctx) as? String
                else -> null
            }
            screenId?.let { DSLAppEngine.navigate(it) }
        }

        register("goBack") { _, _ ->
            DSLInterpreter.shared.popScreen()
        }
    }
}
