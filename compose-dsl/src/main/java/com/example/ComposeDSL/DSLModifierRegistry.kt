package com.example.ComposeDSL

import androidx.compose.ui.Modifier

/** Simple registry to apply modifiers from JSON nodes */
object DSLModifierRegistry {
    private val registry = mutableMapOf<String, (Modifier, Any?, DSLContext) -> Modifier>()

    fun register(name: String, fn: (Modifier, Any?, DSLContext) -> Modifier) {
        registry[name] = fn
    }

    fun apply(list: List<Map<String, Any?>>, base: Modifier, context: DSLContext): Modifier {
        var result = base
        for (mod in list) {
            val key = mod.keys.firstOrNull() ?: continue
            val value = mod[key]
            val fn = registry[key] ?: continue
            result = fn(result, value, context)
        }
        return result
    }

    fun registerDefaults() {
        BaseViewModifiers.registerAll()
    }
}
