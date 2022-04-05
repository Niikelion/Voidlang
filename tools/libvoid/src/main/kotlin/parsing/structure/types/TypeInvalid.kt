package parsing.structure.types

import org.antlr.v4.runtime.ParserRuleContext

class TypeInvalid(ctx: ParserRuleContext): Type(ctx) {
    override fun toString(): String {
        return ":invalid:"
    }
}