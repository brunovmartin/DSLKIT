package com.example.composedsl.ui.components
import com.example.composedsl.core.*
import com.example.composedsl.helper.DSLModifierRegistry

import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.runtime.Composable

object ListComponent {
    fun register() {
        DSLComponentRegistry.register("list") { node, context ->
            val data = DSLExpression.evaluate(node["data"], context)
            val items = data as? List<Map<String, Any?>> ?: emptyList()
            val modifiers = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLModifierRegistry.apply(modifiers, context)
            LazyColumn(modifier = modifier) {
                itemsIndexed(items) { index, item ->
                    val childContext = context.childContext(index)
                    DSLRenderer.renderChildren(listOf(item), childContext)
                }
            }
        }
    }
}
