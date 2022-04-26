package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext

class BinaryOperator(val arg1: Value, val arg2: Value, val op: Op, ctx: ParserRuleContext): Value(ctx) {
    enum class Op {
        Mul, Div, Mod, Add, Sub, LShift, RShift, And, Or, Xor, Eq, Neq, Lt, Gt, Leq, Geq, LAnd, LOr, Assign;
    }

    override fun toString(): String {
        return "$arg1 $op $arg2"
    }
}