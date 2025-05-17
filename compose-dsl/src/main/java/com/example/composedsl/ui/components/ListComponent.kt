package com.example.composedsl.ui.components

import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.runtime.Composable

import com.example.composedsl.core.DSLComponentRegistry
import com.example.composedsl.core.DSLExpression
import com.example.composedsl.core.DSLRenderer

object ListComponent {
    fun register() {
        DSLComponentRegistry.register("list") { node, context ->
            val data = DSLExpression.evaluate(node["data"], context)
            val items = data as? List<Map<String, Any?>> ?: emptyList()
            LazyColumn {
                itemsIndexed(items) { index, item ->
                    val childContext = context.childContext(index)
                    DSLRenderer.renderChildren(listOf(item), childContext)
                }
            }
        }
    }
}
