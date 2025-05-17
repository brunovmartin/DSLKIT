package com.example.composedsl.helper

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.heightIn
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.example.composedsl.core.DSLContext
import com.example.composedsl.core.DSLExpression

object DSLModifierRegistry {
    private val modifiers = mutableMapOf<String, (Modifier, Any?, DSLContext) -> Modifier>()

    fun register(name: String, fn: (Modifier, Any?, DSLContext) -> Modifier) {
        modifiers[name] = fn
    }

    fun apply(list: List<Map<String, Any?>>, context: DSLContext): Modifier {
        var result = Modifier
        for (mod in list) {
            val key = mod.keys.first()
            val value = mod[key]
            val fn = modifiers[key] ?: continue
            result = fn(result, value, context)
        }
        return result
    }

    fun registerDefaults() {
        register("padding") { modifier, value, ctx ->
            val evaluated = DSLExpression.evaluate(value, ctx)
            val all = (evaluated as? Number)?.toFloat()?.dp
            if (all != null) {
                modifier.then(Modifier.padding(all))
            } else {
                modifier
            }
        }

        register("frame") { modifier, value, ctx ->
            val evaluated = DSLExpression.evaluate(value, ctx)
            val params = evaluated as? Map<*, *> ?: return@register modifier
            val width = (params["width"] as? Number)?.toFloat()?.dp
            val height = (params["height"] as? Number)?.toFloat()?.dp
            val maxWidth = (params["maxWidth"] as? Number)?.toFloat()?.dp
            val maxHeight = (params["maxHeight"] as? Number)?.toFloat()?.dp
            val minWidth = (params["minWidth"] as? Number)?.toFloat()?.dp
            val minHeight = (params["minHeight"] as? Number)?.toFloat()?.dp
            modifier
                .then(if (width != null || height != null) Modifier.size(width ?: Dp.Unspecified, height ?: Dp.Unspecified) else Modifier)
                .then(Modifier.widthIn(minWidth ?: Dp.Unspecified, maxWidth ?: Dp.Unspecified))
                .then(Modifier.heightIn(minHeight ?: Dp.Unspecified, maxHeight ?: Dp.Unspecified))
        }

        register("background") { modifier, value, ctx ->
            val evaluated = DSLExpression.evaluate(value, ctx) as? String
            val color = parseColor(evaluated)
            if (color != null) modifier.then(Modifier.background(color)) else modifier
        }
    }

    private fun parseColor(str: String?): Color? {
        if (str == null) return null
        return try { Color(android.graphics.Color.parseColor(str)) } catch (_: Exception) { null }
    }
}
