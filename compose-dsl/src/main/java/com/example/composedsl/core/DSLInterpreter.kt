package com.example.composedsl.core

import androidx.compose.runtime.mutableStateListOf

class DSLInterpreter private constructor() {
    companion object { val shared = DSLInterpreter() }

    val navigationPath = mutableStateListOf<String>()
    private var currentContext: DSLContext? = null
    private var rootScreenId: String? = null

    fun present(screen: Map<String, Any?>, context: DSLContext) {
        currentContext = context
        rootScreenId = screen["id"] as? String
        navigationPath.clear()
    }

    fun pushScreen(id: String) { navigationPath.add(id) }
    fun popScreen() { if (navigationPath.isNotEmpty()) navigationPath.removeLast() }

    fun handleEvent(event: Any?, context: DSLContext) {
        when (event) {
            is Map<*, *> -> DSLCommandRegistry.execute(event as Map<String, Any?>, context)
            is List<*> -> event.forEach { handleEvent(it, context) }
        }
    }

    fun getRootScreenDefinition(): Map<String, Any?>? {
        return rootScreenId?.let { DSLAppEngine.screens[it] }
    }
}
