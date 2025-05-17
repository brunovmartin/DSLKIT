package com.example.composedsl.ui.components
import com.example.composedsl.core.*
import com.example.composedsl.helper.DSLModifierRegistry

import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

object ButtonComponent {
    fun register() {
        DSLComponentRegistry.register("button") { node, context ->
            val titleExpr = node["title"]
            val title = DSLExpression.evaluate(titleExpr, context)?.toString() ?: ""
            val action = node["onTap"]
            val modifiers = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLModifierRegistry.apply(modifiers, context)
            Button(modifier = modifier, onClick = { action?.let { DSLInterpreter.shared.handleEvent(it, context) } }) {
                if (node["children"] is List<*>) {
                    DSLRenderer.renderChildren(node["children"] as List<Map<String, Any?>>, context)
                } else {
                    Text(title)
                }
            }
        }
    }
}
