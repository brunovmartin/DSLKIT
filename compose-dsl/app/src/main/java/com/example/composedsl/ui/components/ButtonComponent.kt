package com.example.composedsl.ui.components

import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.example.composedsl.core.*

object ButtonComponent {
    fun register() {
        DSLComponentRegistry.register("button") { node, context ->
            val titleExpr = node["title"]
            val title = DSLExpression.evaluate(titleExpr, context)?.toString() ?: ""
            val action = node["onTap"]
            val mods = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLComponentRegistry.modifierRegistry.apply(mods, Modifier, context)
            Button(onClick = { action?.let { DSLInterpreter.shared.handleEvent(it, context) } }, modifier = modifier) {
                if (node["children"] is List<*>) {
                    DSLRenderer.renderChildren(node["children"] as List<Map<String, Any?>>, context)
                } else {
                    Text(title)
                }
            }
        }
    }
}
