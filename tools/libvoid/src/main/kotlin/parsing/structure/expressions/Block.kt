package parsing.structure.expressions

import Positional
import org.antlr.v4.runtime.ParserRuleContext

class Block(val expressions: List<Expression>, pos: Positional): Expression(pos) {
    constructor(expressions: List<Expression>, ctx: ParserRuleContext): this(expressions, Positional(ctx))
    constructor(expressions: List<Expression>): this(expressions, Positional(0, 0, ""))

    override fun toString(): String {
        val joinedExpressions = expressions.joinToString("\n")
        return "{\n$joinedExpressions\n}"
    }
}