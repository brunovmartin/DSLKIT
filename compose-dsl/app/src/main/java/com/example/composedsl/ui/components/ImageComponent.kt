package com.example.composedsl.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.platform.LocalContext
import com.example.composedsl.core.*

object ImageComponent {
    fun register() {
        DSLComponentRegistry.register("image") { node, context ->
            val name = DSLExpression.evaluate(node["name"], context)?.toString() ?: return@register
            val resId = LocalContext.current.resources.getIdentifier(name, "drawable", LocalContext.current.packageName)
            val mods = node["modifiers"] as? List<Map<String, Any?>> ?: emptyList()
            val modifier = DSLComponentRegistry.modifierRegistry.apply(mods, Modifier.fillMaxWidth(), context)
            if (resId != 0) {
                Image(painter = painterResource(resId), contentDescription = null, modifier = modifier)
            }
        }
    }
}
