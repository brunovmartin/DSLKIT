package com.example.ComposeDSL

import androidx.compose.runtime.Composable

object DSLRenderer {
    @Composable
    fun renderComponent(node: Map<String, Any?>, context: DSLContext) {
        val type = node["type"] as? String ?: return
        val builder = DSLComponentRegistry.resolve(type)
        builder?.invoke(node, context)
    }

    @Composable
    fun renderChildren(nodes: List<Map<String, Any?>>, context: DSLContext) {
        nodes.forEach { renderComponent(it, context) }
    }
}
