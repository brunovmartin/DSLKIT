package com.example.ComposeDSL

object StringOperators {
    fun registerAll() {
        DSLOperatorRegistry.register("String.trim") { input, _ ->
            (input as? String)?.trim()
        }

        DSLOperatorRegistry.register("String.uppercase") { input, _ ->
            (input as? String)?.uppercase()
        }

        DSLOperatorRegistry.register("String.add") { input, _ ->
            val list = input as? List<*> ?: return@register ""
            list.joinToString(separator = "") { it?.toString() ?: "" }
        }

        DSLOperatorRegistry.register("String.indexOf") { input, _ ->
            val dict = input as? Map<*, *> ?: return@register -1
            val text = dict["source"] as? String ?: return@register -1
            val search = dict["search"] as? String ?: return@register -1
            text.indexOf(search)
        }

        DSLOperatorRegistry.register("String.substring") { input, context ->
            val args = input as? List<*> ?: return@register ""
            if (args.size < 3) return@register ""
            val src = DSLExpression.evaluate(args[0], context) as? String ?: return@register ""
            val start = (DSLExpression.evaluate(args[1], context) as? Number)?.toInt() ?: 0
            val len = (DSLExpression.evaluate(args[2], context) as? Number)?.toInt() ?: 0
            if (start < 0 || len < 0 || start > src.length) return@register ""
            val end = (start + len).coerceAtMost(src.length)
            src.substring(start, end)
        }
    }
}
