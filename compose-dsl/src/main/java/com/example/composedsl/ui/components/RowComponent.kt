package com.example.composedsl.ui.components
import com.example.composedsl.core.*
import com.example.composedsl.helper.DSLModifierRegistry

import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable

object RowComponent {
    fun register() {
        DSLComponentRegistry.register("hstack") { node, context ->
            val modifiers = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLModifierRegistry.apply(modifiers, context)
            Row(modifier = modifier) {
                val children = node["children"] as? List<Map<String, Any?>> ?: emptyList()
                DSLRenderer.renderChildren(children, context)
            }
        }
    }
}
