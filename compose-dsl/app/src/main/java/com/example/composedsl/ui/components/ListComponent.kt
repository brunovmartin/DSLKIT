package com.example.composedsl.ui.components

import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.example.composedsl.core.*
import android.util.Log

object ListComponent {
    fun register() {
        DSLComponentRegistry.register("list") { node, context ->
            val data = DSLExpression.evaluate(node["data"], context)
            Log.d("ListComponent", "Data expression: ${node["data"]} -> $data")
            val items = data as? List<Map<String, Any?>> ?: emptyList()
            val mods = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLComponentRegistry.modifierRegistry.apply(mods, Modifier, context)
            val rowTemplate = node["children"]
            LazyColumn(modifier = modifier) {
                itemsIndexed(items) { index, _ ->
                    val childContext = context.childContext(index)
                    when (rowTemplate) {
                        is Map<*, *> -> DSLRenderer.renderComponent(rowTemplate as Map<String, Any?>, childContext)
                        is List<*> -> DSLRenderer.renderChildren(rowTemplate as List<Map<String, Any?>>, childContext)
                    }
                }
            }
        }
    }
}
