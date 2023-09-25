package parsing.structure.expressions

import Positional
import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.Token

open class Expression(private val positional: Positional): Token {
    override fun getOrigin(): Positional {
        return positional
    }

    constructor(ctx: ParserRuleContext) : this(Positional(ctx))
}