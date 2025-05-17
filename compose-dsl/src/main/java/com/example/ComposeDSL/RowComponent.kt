package com.example.ComposeDSL

import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

object RowComponent {
    fun register() {
        DSLComponentRegistry.register("hstack") { node, context ->
            val modifier = modifierFromNode(node, context)
            Row(modifier = modifier) {
                val children = node["children"] as? List<Map<String, Any?>> ?: emptyList()
                DSLRenderer.renderChildren(children, context)
            }
        }
    }
}
