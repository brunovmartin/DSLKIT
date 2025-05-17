package com.example.composedsl.ui.components

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.example.composedsl.core.*

object TextComponent {
    fun register() {
        DSLComponentRegistry.register("text") { node, context ->
            val value = DSLExpression.evaluate(node["value"], context)
            val mods = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLComponentRegistry.modifierRegistry.apply(mods, Modifier, context)
            Text(value?.toString() ?: "", modifier = modifier)
        }
    }
}
