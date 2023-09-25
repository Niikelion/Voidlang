package parsing.structure.expressions

import Positional
import org.antlr.v4.runtime.ParserRuleContext

class Noop(positional: Positional): Expression(positional) {
    constructor(ctx: ParserRuleContext): this(Positional(ctx))
    constructor(): this(Positional(0, 0, ""))
}