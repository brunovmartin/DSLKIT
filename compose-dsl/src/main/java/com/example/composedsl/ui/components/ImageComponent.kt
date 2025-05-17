package com.example.composedsl.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.platform.LocalContext

import com.example.composedsl.core.DSLComponentRegistry
import com.example.composedsl.core.DSLExpression

object ImageComponent {
    fun register() {
        DSLComponentRegistry.register("image") { node, context ->
            val name = DSLExpression.evaluate(node["name"], context)?.toString() ?: return@register
            val ctx = LocalContext.current
            val resId = ctx.resources.getIdentifier(name, "drawable", ctx.packageName)
            if (resId != 0) {
                Image(painter = painterResource(resId), contentDescription = null, modifier = Modifier.fillMaxWidth())
            }
        }
    }
}
