package com.example.composedsl.core

import com.example.composedsl.operators.LogicOperators
import com.example.composedsl.operators.MathOperators
import com.example.composedsl.operators.StringOperators
object DSLOperatorRegistry {
    private val registry = mutableMapOf<String, (Any?, DSLContext) -> Any?>()

    fun register(name: String, fn: (Any?, DSLContext) -> Any?) {
        registry[name] = fn
    }

    fun evaluate(name: String, input: Any?, context: DSLContext): Any? {
        val op = registry[name] ?: return null
        return op(input, context)
    }

    fun isRegistered(name: String) = registry.containsKey(name)

    fun registerDefaults() {
        StringOperators.registerAll()
        MathOperators.registerAll()
        LogicOperators.registerAll()
        // Additional operator sets can be added here
    }
}
