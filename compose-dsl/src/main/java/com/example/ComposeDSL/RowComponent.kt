package com.example.ComposeDSL

import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable

object RowComponent {
    fun register() {
        DSLComponentRegistry.register("hstack") { node, context ->
            Row {
                val children = node["children"] as? List<Map<String, Any?>> ?: emptyList()
                DSLRenderer.renderChildren(children, context)
            }
        }
    }
}
