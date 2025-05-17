package com.example.composedsl.ui.components

import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.example.composedsl.core.*

object RowComponent {
    fun register() {
        DSLComponentRegistry.register("hstack") { node, context ->
            val mods = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLComponentRegistry.modifierRegistry.apply(mods, Modifier, context)
            Row(modifier = modifier) {
                val children = node["children"] as? List<Map<String, Any?>> ?: emptyList()
                DSLRenderer.renderChildren(children, context)
            }
        }
    }
}
