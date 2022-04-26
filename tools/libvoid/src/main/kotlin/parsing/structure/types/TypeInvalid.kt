package parsing.structure.types

import Positional
import org.antlr.v4.runtime.ParserRuleContext

class TypeInvalid(pos: Positional): Type(pos) {
    constructor(ctx: ParserRuleContext): this(Positional(ctx))
    constructor(): this(Positional(0, 0, ""))

    override fun toString(): String {
        return ":invalid:"
    }
}