package com.example.composedsl.ui.components
import com.example.composedsl.core.*
import com.example.composedsl.helper.DSLModifierRegistry

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource

object ImageComponent {
    fun register() {
        DSLComponentRegistry.register("image") { node, context ->
            val name = DSLExpression.evaluate(node["name"], context)?.toString() ?: return@register
            val modifiers = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLModifierRegistry.apply(modifiers, context).then(Modifier.fillMaxWidth())
            Image(painter = painterResource(name), contentDescription = null, modifier = modifier)
        }
    }
}
