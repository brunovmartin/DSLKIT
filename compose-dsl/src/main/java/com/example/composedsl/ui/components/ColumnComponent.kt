package com.example.composedsl.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable

import com.example.composedsl.core.DSLComponentRegistry
import com.example.composedsl.core.DSLRenderer

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
