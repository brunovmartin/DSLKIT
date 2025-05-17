package com.example.composedsl.ui.components

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

import com.example.composedsl.core.DSLComponentRegistry
import com.example.composedsl.core.DSLExpression

object TextComponent {
    fun register() {
        DSLComponentRegistry.register("text") { node, context ->
            val value = DSLExpression.evaluate(node["value"], context)
            Text(value?.toString() ?: "")
        }
    }
}
