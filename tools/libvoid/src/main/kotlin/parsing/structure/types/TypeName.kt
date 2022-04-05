package parsing.structure.types

import Positional
import org.antlr.v4.runtime.ParserRuleContext

class TypeName(ctx: ParserRuleContext, val name: String): Type(ctx) {
    override fun toString(): String {
        return name;
    }
}