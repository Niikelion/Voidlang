package parsing.structure.types

import org.antlr.v4.runtime.ParserRuleContext

class TypeTemplate(val base: Type, val args: List<Type>, ctx: ParserRuleContext): Type(ctx) {
    override fun toString(): String {
        val arg = args.joinToString(separator = ",")
        return "$base<$arg>"
    }
}