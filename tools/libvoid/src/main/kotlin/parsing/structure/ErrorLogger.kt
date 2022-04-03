package parsing.structure

import VoidError
import org.antlr.v4.runtime.ParserRuleContext

class StructureError(
    line: Int,
    pos: Int,
    source: String? = null,
    private val msg: String
): VoidError(line, pos, source) {
    override fun getErrorMsg(): String {
        return "syntax error - $msg"
    }
}

class ErrorLogger(private val source: String) {
    private val subscriptions = mutableListOf<(VoidError) -> Unit>()

    fun subscribe(callback: (VoidError) -> Unit) {
        subscriptions.add(callback)
    }

    fun publish(err: VoidError) {
        subscriptions.forEach { s -> s.invoke(err) }
    }

    fun structureError(ctx: ParserRuleContext, msg: String): Nothing? {
        publish(
            StructureError(
                ctx.getStart().line,
                ctx.getStart().charPositionInLine,
                source,
                msg
            ) as VoidError
        )
        return null
    }
}