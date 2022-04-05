import org.antlr.v4.runtime.ParserRuleContext

open class Positional(val line: Int, val pos: Int, dataSource: String? = null) {
    val source = dataSource ?: "input"

    constructor(ctx: ParserRuleContext) : this(
        ctx.getStart()?.line ?: 0,
        ctx.getStart()?.charPositionInLine ?: 0,
        ctx.getStart()?.tokenSource?.sourceName ?: "input"
    )
}