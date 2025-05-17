package com.example.ComposeDSL

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource

object ImageComponent {
    fun register() {
        DSLComponentRegistry.register("image") { node, context ->
            val modifier = modifierFromNode(node, context).then(Modifier.fillMaxWidth())
            val name = DSLExpression.evaluate(node["name"], context)?.toString() ?: return@register
            Image(painter = painterResource(name), contentDescription = null, modifier = modifier)
        }
    }
}
