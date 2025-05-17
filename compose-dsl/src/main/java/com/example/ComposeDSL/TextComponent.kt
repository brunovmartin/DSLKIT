package com.example.ComposeDSL

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

object TextComponent {
    fun register() {
        DSLComponentRegistry.register("text") { node, context ->
            val modifier = modifierFromNode(node, context)
            val value = DSLExpression.evaluate(node["value"], context)
            Text(value?.toString() ?: "", modifier = modifier)
        }
    }
}
