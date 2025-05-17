package com.example.composedsl.core

import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width

class DSLModifierRegistry {
    private val modifiers = mutableMapOf<String, (Modifier, Any?, DSLContext) -> Modifier>()

    fun register(name: String, fn: (Modifier, Any?, DSLContext) -> Modifier) {
        modifiers[name] = fn
    }

    fun apply(list: List<Map<String, Any?>>, base: Modifier, ctx: DSLContext): Modifier {
        return list.fold(base) { current, mod ->
            val key = mod.keys.firstOrNull() ?: return@fold current
            val value = mod[key]
            val fn = modifiers[key] ?: return@fold current
            fn(current, value, ctx)
        }
    }

    fun registerDefaults() {
        register("padding") { mod, value, _ ->
            val all = (value as? Number)?.toInt()?.dp
            val map = value as? Map<*, *>
            when {
                all != null -> mod.then(Modifier.padding(all))
                map != null -> {
                    val start = (map["start"] as? Number)?.toInt()?.dp ?: 0.dp
                    val top = (map["top"] as? Number)?.toInt()?.dp ?: 0.dp
                    val end = (map["end"] as? Number)?.toInt()?.dp ?: 0.dp
                    val bottom = (map["bottom"] as? Number)?.toInt()?.dp ?: 0.dp
                    mod.then(Modifier.padding(start, top, end, bottom))
                }
                else -> mod
            }
        }

        register("frame") { mod, value, _ ->
            val map = value as? Map<*, *> ?: return@register mod
            var m = mod
            (map["width"] as? Number)?.toInt()?.dp?.let { m = m.then(Modifier.width(it)) }
            (map["height"] as? Number)?.toInt()?.dp?.let { m = m.then(Modifier.height(it)) }
            m
        }

        register("backgroundColor") { mod, value, _ ->
            val str = value as? String ?: return@register mod
            val color = try { Color(android.graphics.Color.parseColor(str)) } catch (e: IllegalArgumentException) { Color.Transparent }
            mod.then(Modifier.background(color))
        }
    }
}
