package parsing.structure.types

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.Member

class LambdaObjectType(ctx: ParserRuleContext, val members: List<Member>): Type(ctx) {
    override fun toString(): String {
        val members = members.joinToString(", ")
        return "{ $members }"
    }
}