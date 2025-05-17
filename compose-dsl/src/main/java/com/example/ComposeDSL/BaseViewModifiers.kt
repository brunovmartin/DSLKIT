package com.example.ComposeDSL

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.Color

object BaseViewModifiers {
    fun registerAll() {
        DSLModifierRegistry.register("padding") { mod, value, ctx ->
            val evaluated = DSLExpression.evaluate(value, ctx)
            val padding = (evaluated as? Number)?.toFloat() ?: 0f
            mod.then(Modifier.padding(padding.dp))
        }

        DSLModifierRegistry.register("background") { mod, value, ctx ->
            val color = parseColor(DSLExpression.evaluate(value, ctx))
            if (color != null) mod.then(Modifier.background(color)) else mod
        }

        DSLModifierRegistry.register("frame") { mod, value, ctx ->
            val map = value as? Map<*, *> ?: return@register mod
            val width = (DSLExpression.evaluate(map["width"], ctx) as? Number)?.toFloat()
            val height = (DSLExpression.evaluate(map["height"], ctx) as? Number)?.toFloat()
            var m = mod
            if (width != null && height != null) {
                m = m.then(Modifier.size(width.dp, height.dp))
            } else if (width != null) {
                m = m.then(Modifier.width(width.dp))
            } else if (height != null) {
                m = m.then(Modifier.height(height.dp))
            }
            m
        }

        DSLModifierRegistry.register("cornerRadius") { mod, value, ctx ->
            val radius = (DSLExpression.evaluate(value, ctx) as? Number)?.toFloat() ?: return@register mod
            mod.then(Modifier.clip(RoundedCornerShape(radius.dp)))
        }
    }
}

fun parseColor(value: Any?): Color? {
    val str = value as? String ?: return null
    if (str.startsWith("#")) {
        val hex = str.removePrefix("#")
        val colorLong = hex.toLongOrNull(16) ?: return null
        return when (hex.length) {
            6 -> Color((0xFF000000 or colorLong).toInt())
            8 -> Color(colorLong.toInt())
            else -> null
        }
    }
    return when (str.lowercase()) {
        "black" -> Color.Black
        "blue" -> Color.Blue
        "green" -> Color.Green
        "red" -> Color.Red
        "white" -> Color.White
        "gray" -> Color.Gray
        "yellow" -> Color.Yellow
        "cyan" -> Color.Cyan
        "magenta" -> Color.Magenta
        "transparent" -> Color.Transparent
        else -> null
    }
}
