package parsing.structure.types

import Positional
import org.antlr.v4.runtime.ParserRuleContext

class TypeName(val name: String, ctx: ParserRuleContext): Type(ctx) {
    override fun toString(): String {
        return name;
    }
}