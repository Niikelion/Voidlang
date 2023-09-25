package parsing.structure.functions

import parsing.structure.ErrorLogger
import VoidParserBaseVisitor
import arrow.core.Nullable
import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.VisitorPack
import parsing.structure.expressions.Block
import parsing.structure.expressions.ReturnExpression
import parsing.structure.types.TypeAuto
import parsing.structure.types.TypeInvalid
import parsing.structure.values.Function

class FunctionVisitor(
    private val errorLogger: ErrorLogger,
    private val p: VisitorPack
): VoidParserBaseVisitor<Function>() {

    fun getFunction(ctx: ParserRuleContext): Function {
        return visit(ctx) ?: run {
            errorLogger.structureError(ctx, "function expected expected")
            Function(listOf(), TypeInvalid(), Block(listOf()), false, ctx)
        }
    }

    override fun visitCstyleFunctionDef(ctx: VoidParser.CstyleFunctionDefContext?): Function? {
        if (ctx == null)
            return null

        val fSig = ctx.functionDefSignature()

        val retType = fSig ?. typeExpression() ?. let { p.getType(it) }
        val args = fSig ?. argumentsDef() ?. argumentDef() ?. mapNotNull { i ->
            i?.run {
                val type = i.typeExpression()?.let { p.getType(it) } ?: TypeAuto(i)
                val name = i.identifier()?.text
                name?.let { Function.ArgDef(type, name) } ?: run {
                    errorLogger.structureError(i, "invalid argument name")
                }
            }
            ?: run {
                errorLogger.structureError(ctx, "missing argument definition")
            }
        }

        val body = ctx.functionBody() ?. let { p.getFunctionBody(it) }
        return Nullable.zip(args, body, retType) { a, b, r -> run {
            Function(a, r, b, true, ctx)
        } }
    }

    override fun visitArrowFunctionDef(ctx: VoidParser.ArrowFunctionDefContext?): Function? {
        if (ctx == null)
            return null

        val fSig = ctx.functionDefSignature()

        val retType = fSig ?. typeExpression() ?. let { p.getType(it) }
        val args = fSig ?. argumentsDef() ?. argumentDef() ?. mapNotNull { i ->
            i?.run {
                val type = i.typeExpression()?.let { p.getType(it) } ?: TypeAuto(i)
                val name = i.identifier()?.text
                name?.let { Function.ArgDef(type, name) } ?: run {
                    errorLogger.structureError(i, "invalid argument name")
                }
            }
                ?: run {
                    errorLogger.structureError(ctx, "missing argument definition")
                }
        }

        val body = ctx.valueExpression() ?. let { Block(listOf(ReturnExpression(p.getValue(it), it)), it) }
        return Nullable.zip(args, body, retType) { a, b, r -> run {
            Function(a, r, b, true, ctx)
        } }
    }
}