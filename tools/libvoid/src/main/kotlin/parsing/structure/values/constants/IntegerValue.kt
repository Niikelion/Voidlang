package parsing.structure.values.constants

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.values.Value
import java.math.BigInteger

class IntegerValue(val value: BigInteger , ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        return "int($value)"
    }
}