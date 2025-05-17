package com.example.composedsl.ui.components
import com.example.composedsl.core.*
import com.example.composedsl.helper.DSLModifierRegistry

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

object TextComponent {
    fun register() {
        DSLComponentRegistry.register("text") { node, context ->
            val value = DSLExpression.evaluate(node["value"], context)
            val modifiers = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLModifierRegistry.apply(modifiers, context)
            Text(value?.toString() ?: "", modifier = modifier)
        }
    }
}
