package com.example.composedsl.operators
import com.example.composedsl.core.DSLContext

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
