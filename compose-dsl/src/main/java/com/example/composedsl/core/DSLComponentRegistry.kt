package com.example.composedsl.core

import androidx.compose.runtime.Composable

import com.example.composedsl.core.DSLModifierRegistry
typealias ComponentBuilder = @Composable (node: Map<String, Any?>, context: DSLContext) -> Unit

object DSLComponentRegistry {
    private val components = mutableMapOf<String, ComponentBuilder>()
    val modifierRegistry = DSLModifierRegistry()

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
