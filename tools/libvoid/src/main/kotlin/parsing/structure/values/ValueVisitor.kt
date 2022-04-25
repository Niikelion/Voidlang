package parsing.structure.values

import VoidParserBaseVisitor
import VoidParser
import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.ErrorLogger
import parsing.structure.expressions.Expression
import parsing.structure.types.TypeAuto
import parsing.structure.types.TypeInvalid
import parsing.structure.types.TypeVisitor
import parsing.structure.values.constants.IntegerValue
import parsing.structure.values.constants.InvalidValue
import parsing.structure.values.constants.ObjectValue
import parsing.structure.values.constants.StringValue
import java.math.BigInteger

class ValueVisitor(private val errorLogger: ErrorLogger, tV: TypeVisitor? = null): VoidParserBaseVisitor<Value?>() {
    private val typeVisitor: TypeVisitor = tV ?: TypeVisitor(errorLogger)

    fun getValue(ctx: ParserRuleContext): Value {
        return visit(ctx) ?: run {
            errorLogger.structureError(ctx, "value expected")
            InvalidValue(ctx)
        }
    }

    override fun visitSimplifiedAutoLambda(ctx: VoidParser.SimplifiedAutoLambdaContext?): Value? {
        return ctx ?. identifier() ?. text ?. let { name -> run {
            //TODO: use ExpressionVisitor to generate body
            val body: List<Expression> = listOf()
            LambdaFunction(listOf(LambdaFunction.ArgDef(TypeAuto(ctx), name)), TypeAuto(ctx), body, ctx)
        } }
    }

    override fun visitAutoLambda(ctx: VoidParser.AutoLambdaContext?): Value? {
        return ctx ?. run {
            val args = ctx.identifier() ?. mapNotNull { i -> i ?. let { LambdaFunction.ArgDef(TypeAuto(i), i.text) } ?: run {
                errorLogger.structureError(ctx, "invalid argument name")
            } }
            val retType = ctx.
            null
        }
    }

    override fun visitNumericConstant(ctx: VoidParser.NumericConstantContext?): Value? {
        return ctx ?. run {
            ctx.DecimalNumber() ?.let { IntegerValue(BigInteger(it.text), ctx) } ?:
            ctx.HexadecimalNumber() ?. let { IntegerValue(BigInteger(it.text.drop(2), 16), ctx) } ?:
            InvalidValue(ctx)
        }
    }

    override fun visitStringConstant(ctx: VoidParser.StringConstantContext?): Value? {
        return ctx ?. SimpleString() ?.let { StringValue(it.text, ctx) }
    }

    override fun visitVariableExpression(ctx: VoidParser.VariableExpressionContext?): Value? {
        return ctx ?. identifier() ?. Name() ?. let { VariableAccess(it.text, ctx) }
    }

    override fun visitLambdaTuple(ctx: VoidParser.LambdaTupleContext?): Value? {
        return ctx ?. run {
            val values = ctx.valueExpression().mapNotNull { it ?. run { getValue(it) } ?: InvalidValue(ctx) }
            TupleValue(values, ctx)
        }
    }

    override fun visitLambdaObject(ctx: VoidParser.LambdaObjectContext?): Value? {
        return ctx ?. run {
            val members = ctx.lambdaObjectMember().mapNotNull { it ?. run {
                it.identifier() ?. text ?. let { name -> run {
                    val type = it.typeExpression() ?. let { t -> typeVisitor.getType(t) } ?: TypeInvalid(it)
                    val value = it.valueExpression() ?. let { v -> getValue(v) }

                    ObjectValue.ObjectSubDecl(type, name, value)
                } } ?: run {
                    errorLogger.structureError(it, "invalid member")
                }
            } }
            ObjectValue(members, ctx)
        }
    }

    override fun visitAsCast(ctx: VoidParser.AsCastContext?): Value? {
        return ctx ?. castExpression() ?. let { valueExp -> ctx.typeExpression() ?. let { typeExp -> run {
            val value = getValue(valueExp)
            val type = typeVisitor.getType(typeExp)
            ValueCast(value, type, ctx)
        } } }
    }
}