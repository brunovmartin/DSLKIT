package com.example.composedsl.ui.components

import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

import com.example.composedsl.core.DSLComponentRegistry
import com.example.composedsl.core.DSLExpression
import com.example.composedsl.core.DSLInterpreter
import com.example.composedsl.core.DSLRenderer

object ButtonComponent {
    fun register() {
        DSLComponentRegistry.register("button") { node, context ->
            val titleExpr = node["title"]
            val title = DSLExpression.evaluate(titleExpr, context)?.toString() ?: ""
            val action = node["onTap"]
            Button(onClick = { action?.let { DSLInterpreter.shared.handleEvent(it, context) } }) {
                if (node["children"] is List<*>) {
                    DSLRenderer.renderChildren(node["children"] as List<Map<String, Any?>>, context)
                } else {
                    Text(title)
                }
            }
        }
    }
}
