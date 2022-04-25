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

    override fun visitMemberAccess(ctx: VoidParser.MemberAccessContext?): Value? {
        return ctx ?. run {
            val source = ctx.accessExpression() ?. let { getValue(it) }
            val member = ctx.variableExpression() ?. identifier() ?. text
            //source ?.
            null
        }
    }

    override fun visitCtorInvoke(ctx: VoidParser.CtorInvokeContext?): Value? {
        return ctx ?. run {
            val type = ctx.typeExpression() ?. let { typeVisitor.getType(it) } ?: TypeInvalid(ctx)
            val args = ctx.ctorInit()?.valueExpression()?.mapNotNull { v -> v ?. run { getValue(v) } ?: run {
                errorLogger.structureError(ctx, "missing constructor argument")
            } }

            args ?. run {
                ConstructorInvoke(type, args, ctx)
            } ?: run {
                errorLogger.structureError(ctx, "missing constructor arguments")
                InvalidValue(ctx)
            }
        }
    }

    override fun visitSimplifiedLambda(ctx: VoidParser.SimplifiedLambdaContext?): Value? {
        return ctx ?. identifier() ?. text ?. let { name -> run {
            //TODO: use ExpressionVisitor to generate body
            val body: List<Expression> = listOf()
            LambdaFunction(listOf(LambdaFunction.ArgDef(TypeAuto(ctx), name)), TypeAuto(ctx), body, ctx)
        } }
    }

    override fun visitConventionalLambda(ctx: VoidParser.ConventionalLambdaContext?): Value? {
        return ctx ?. run {
            val retType = ctx.typeExpression() ?. let { typeVisitor.getType(it) } ?: TypeAuto(ctx)
            val args = ctx.lambdaFunctionArgDef() ?. mapNotNull {
                i -> i ?. run {
                    val type = i.typeExpression() ?. let { typeVisitor.getType(it) } ?: TypeAuto(i)
                    val name = i.identifier()?.text
                    name ?. let { LambdaFunction.ArgDef(type, name) } ?: run {
                        errorLogger.structureError(i, "invalid argument name")
                    }
                }
                ?: run {
                    errorLogger.structureError(ctx, "missing argument definition")
                }
            }
            //TODO: use ExpressionVisitor to generate body
            val body: List<Expression> = listOf()

            args ?. run {
                LambdaFunction(args, retType, body, ctx)
            } ?: run {
                errorLogger.structureError(ctx, "missing lambda arguments")
            }
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