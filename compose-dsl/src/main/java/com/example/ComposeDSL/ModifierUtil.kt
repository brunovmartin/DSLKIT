package com.example.ComposeDSL

import androidx.compose.ui.Modifier

fun modifierFromNode(node: Map<String, Any?>, context: DSLContext): Modifier {
    val mods = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
    return DSLModifierRegistry.apply(mods, Modifier, context)
}
