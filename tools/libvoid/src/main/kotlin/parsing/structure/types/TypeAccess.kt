package parsing.structure.types

import org.antlr.v4.runtime.ParserRuleContext

class TypeAccess(ctx: ParserRuleContext, val parent: Type, var child: Type): Type(ctx) {
    override fun toString(): String {
        return "$parent.$child"
    }
}