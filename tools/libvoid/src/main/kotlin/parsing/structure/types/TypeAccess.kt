package parsing.structure.types

import org.antlr.v4.runtime.ParserRuleContext

class TypeAccess(val parent: Type, var child: Type, ctx: ParserRuleContext): Type(ctx) {
    override fun toString(): String {
        return "$parent.$child"
    }
}