package com.example.ComposeDSL

import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable

object ColumnComponent {
    fun register() {
        DSLComponentRegistry.register("vstack") { node, context ->
            Column {
                val children = node["children"] as? List<Map<String, Any?>> ?: emptyList()
                DSLRenderer.renderChildren(children, context)
            }
        }
    }
}
