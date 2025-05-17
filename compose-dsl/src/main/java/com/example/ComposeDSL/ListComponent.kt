package com.example.ComposeDSL

import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

object ListComponent {
    fun register() {
        DSLComponentRegistry.register("list") { node, context ->
            val modifier = modifierFromNode(node, context)
            val data = DSLExpression.evaluate(node["data"], context)
            val items = data as? List<Map<String, Any?>> ?: emptyList()
            LazyColumn(modifier = modifier) {
                itemsIndexed(items) { index, item ->
                    val childContext = context.childContext(index)
                    DSLRenderer.renderChildren(listOf(item), childContext)
                }
            }
        }
    }
}
