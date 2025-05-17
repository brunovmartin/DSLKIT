package com.example.composedsl.ui.components

import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable

import com.example.composedsl.core.DSLComponentRegistry
import com.example.composedsl.core.DSLRenderer

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
