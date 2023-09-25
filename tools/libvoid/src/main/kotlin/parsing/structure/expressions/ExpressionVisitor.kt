package parsing.structure.expressions

import VoidParser
import VoidParserBaseVisitor
import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.ErrorLogger
import parsing.structure.VisitorPack

class ExpressionVisitor(
    private val errorLogger: ErrorLogger,
    private val p: VisitorPack
): VoidParserBaseVisitor<Expression?>() {

    private fun getExpression(ctx: ParserRuleContext): Expression {
        return visit(ctx) ?: run {
            errorLogger.structureError(ctx, "expression expected")
            Noop(ctx)
        }
    }

    override fun visitValueExpression(ctx: VoidParser.ValueExpressionContext?): Expression? {
        return ctx ?. let { ValueExpression(p.getValue(it)) }
    }

    fun getFunctionBody(ctx: VoidParser.FunctionBodyContext): Block {
        val block = ctx.valueExpression() ?. let { Block(listOf(ReturnExpression(p.getValue(it), it))) }
            ?: ctx.expression() ?. mapNotNull { e -> e ?. let { getExpression(e) } ?: Noop() } ?. let { Block(it) }
        return block ?: Block(listOf())
    }

    override fun visitBlockExp(ctx: VoidParser.BlockExpContext?): Expression? {
        return ctx ?. expression() ?. mapNotNull { getExpression(it) } ?. let { Block(it, ctx) }
    }

    override fun visitCommonDeclaration(ctx: VoidParser.CommonDeclarationContext?): Expression? {
        return ctx ?. varDeclaration() ?. let { VariableDeclarationExp(p.getDeclaration(it), it) }
    }

    override fun visitStatedExp(ctx: VoidParser.StatedExpContext?): Expression? {
        TODO("Implement!")
    }

    override fun visitStatelessExp(ctx: VoidParser.StatelessExpContext?): Expression? {
        TODO("Implement")
    }

    override fun visitReturnExpression(ctx: VoidParser.ReturnExpressionContext?): Expression? {
        return ctx ?. let {
            val value = it.valueExpression() ?. let { v -> p.getValue(v) }
            ReturnExpression(value, it)
        }
    }

    override fun visitIfElseExp(ctx: VoidParser.IfElseExpContext?): Expression? {
        TODO("Implement")
    }
}