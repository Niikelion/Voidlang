package parsing.structure

import VoidError
import org.antlr.v4.runtime.ParserRuleContext
import parsing.StructureError

class ErrorLogger(private val source: String) {
    private val subscribtions = mutableListOf<(VoidError) -> Unit>()

    fun subscribe(callback: (VoidError) -> Unit) {
        subscribtions.add(callback)
    }

    fun publish(err: VoidError) {
        subscribtions.forEach { s -> s.invoke(err) }
    }

    fun structureError(ctx: ParserRuleContext, msg: String) {
        publish(
            StructureError(
                ctx.getStart().line,
                ctx.getStart().charPositionInLine,
                source,
                msg
            ) as VoidError
        )
    }
}