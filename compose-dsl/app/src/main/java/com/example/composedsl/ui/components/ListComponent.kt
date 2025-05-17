package com.example.composedsl.ui.components

import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.example.composedsl.core.*

object ListComponent {
    fun register() {
        DSLComponentRegistry.register("list") { node, context ->
            val data = DSLExpression.evaluate(node["data"], context)
            val items = data as? List<Map<String, Any?>> ?: emptyList()
            val mods = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLComponentRegistry.modifierRegistry.apply(mods, Modifier, context)
            LazyColumn(modifier = modifier) {
                itemsIndexed(items) { index, item ->
                    val childContext = context.childContext(index)
                    DSLRenderer.renderChildren(listOf(item), childContext)
                }
            }
        }
    }
}
