package com.example.ComposeDSL

import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

object ColumnComponent {
    fun register() {
        DSLComponentRegistry.register("vstack") { node, context ->
            val modifier = modifierFromNode(node, context)
            Column(modifier = modifier) {
                val children = node["children"] as? List<Map<String, Any?>> ?: emptyList()
                DSLRenderer.renderChildren(children, context)
            }
        }
    }
}
