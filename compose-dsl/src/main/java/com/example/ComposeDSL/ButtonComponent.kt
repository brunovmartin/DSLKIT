package com.example.ComposeDSL

import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

object ButtonComponent {
    fun register() {
        DSLComponentRegistry.register("button") { node, context ->
            val titleExpr = node["title"]
            val title = DSLExpression.evaluate(titleExpr, context)?.toString() ?: ""
            val action = node["onTap"]
            val modifier = modifierFromNode(node, context)
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
