package com.example.ComposeDSL

import androidx.compose.runtime.Composable

typealias ComponentBuilder = @Composable (node: Map<String, Any?>, context: DSLContext) -> Unit

object DSLComponentRegistry {
    private val components = mutableMapOf<String, ComponentBuilder>()

    fun register(type: String, builder: ComponentBuilder) {
        components[type] = builder
    }

    fun resolve(type: String): ComponentBuilder? = components[type]

    fun registerDefaults() {
        ButtonComponent.register()
        TextComponent.register()
        ImageComponent.register()
        ColumnComponent.register()
        RowComponent.register()
        ListComponent.register()
    }
}
