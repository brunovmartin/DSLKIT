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
            val items = data as? List<*> ?: emptyList<Any?>()
            val mods = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLComponentRegistry.modifierRegistry.apply(mods, Modifier, context)

            val rowTemplate = node["children"] as? Map<String, Any?>
            Log.d("ListComponent", "Row template: $rowTemplate")

            LazyColumn(modifier = modifier) {
                itemsIndexed(items) { index, _ ->
                    val childContext = context.childContext(index)
                    rowTemplate?.let { DSLRenderer.renderComponent(it, childContext) }
                }
            }
        }
    }
}
