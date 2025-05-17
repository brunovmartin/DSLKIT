package com.example.ComposeDSL

import androidx.compose.runtime.mutableStateMapOf

class DSLContext(initial: Map<String, Any?> = emptyMap()) {
    val storage = mutableStateMapOf<String, Any?>().apply { putAll(initial) }
    var currentIndex: Int? = null

    operator fun get(key: String): Any? = storage[key]
    operator fun set(key: String, value: Any?) {
        storage[key] = value
    }

    fun childContext(index: Int): DSLContext {
        val child = DSLContext(storage)
        child.currentIndex = index
        return child
    }
}
