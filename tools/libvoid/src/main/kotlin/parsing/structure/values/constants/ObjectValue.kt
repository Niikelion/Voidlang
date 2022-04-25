package parsing.structure.values.constants

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.types.Type
import parsing.structure.values.Value

class ObjectValue(val members: List<ObjectSubDecl>, ctx: ParserRuleContext): Value(ctx) {
    class ObjectSubDecl(val type: Type, val name: String, val value: Value?) {
        override fun toString(): String {
            val rest = value ?. let { "=$it" } ?: ""
            return "$type $name$rest"
        }
    }

    override fun toString(): String {
        val mem = members.joinToString { ", " }
        return "{$mem}"
    }
}