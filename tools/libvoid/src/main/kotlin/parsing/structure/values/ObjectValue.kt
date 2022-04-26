package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.types.Type
import parsing.structure.types.TypeAuto
import parsing.structure.types.TypeInvalid

class ObjectValue(val members: List<ObjectSubDecl>, ctx: ParserRuleContext): Value(ctx) {
    class ObjectSubDecl(val type: Type, val name: String, val value: Value?) {
        override fun toString(): String {
            val rest = value ?. let { " = $it" } ?: ""
            val t = when (type) {
                is TypeAuto -> if (value != null) "" else "${TypeInvalid()} "
                else -> "$type "
            }
            return "$t$name$rest"
        }
    }

    override fun toString(): String {
        val mem = members.joinToString (", ")
        return "{$mem}"
    }
}