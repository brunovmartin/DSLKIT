package com.example.ComposeDSL

object ArrayOperators {
    fun registerAll() {
        DSLOperatorRegistry.register("Array.indexOf") { input, _ ->
            val dict = input as? Map<*, *> ?: return@register -1
            val array = dict["source"] as? List<*> ?: return@register -1
            val search = dict["search"]
            array.indexOfFirst { "$it" == "$search" }
        }

        DSLOperatorRegistry.register("Array.contains") { input, _ ->
            val dict = input as? Map<*, *> ?: return@register false
            val array = dict["source"] as? List<*> ?: return@register false
            val search = dict["search"]
            array.any { "$it" == "$search" }
        }
    }
}
