package com.example.ComposeDSL

object LogicOperators {
    fun registerAll() {
        DSLOperatorRegistry.register("Logic.eq") { input, _ ->
            val list = input as? List<*> ?: return@register false
            if (list.size != 2) return@register false
            list[0] == list[1]
        }

        DSLOperatorRegistry.register("Logic.neq") { input, _ ->
            val list = input as? List<*> ?: return@register true
            if (list.size != 2) return@register true
            list[0] != list[1]
        }

        DSLOperatorRegistry.register("Logic.and") { input, _ ->
            val list = input as? List<*> ?: return@register false
            list.all { it as? Boolean ?: false }
        }

        DSLOperatorRegistry.register("Logic.or") { input, _ ->
            val list = input as? List<*> ?: return@register false
            list.any { it as? Boolean ?: false }
        }

        DSLOperatorRegistry.register("Logic.not") { input, _ ->
            val bool = input as? Boolean ?: return@register false
            !bool
        }
    }
}
