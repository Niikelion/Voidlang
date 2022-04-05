package parsing.structure.types

import org.antlr.v4.runtime.ParserRuleContext

class TypeTemplate(ctx: ParserRuleContext, val base: Type, val args: List<Type>): Type(ctx) {
    override fun toString(): String {
        val arg = args.joinToString(separator = ",")
        return "$base<$args>"
    }
}