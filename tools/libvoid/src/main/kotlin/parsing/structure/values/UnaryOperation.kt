package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext

class UnaryOperation(val argument: Value, val op: Op, val postfix: Boolean, ctx: ParserRuleContext): Value(ctx) {
    enum class Op {
        Inc, Dec
    }

    override fun toString(): String {
        return if (postfix) "$argument $op" else "$op $argument"
    }
}