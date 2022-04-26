package parsing.structure.values

import VoidParserBaseVisitor
import VoidParser
import arrow.core.Nullable
import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.ErrorLogger
import parsing.structure.expressions.Expression
import parsing.structure.types.TypeAuto
import parsing.structure.types.TypeInvalid
import parsing.structure.types.TypeVisitor
import parsing.structure.values.constants.IntegerValue
import parsing.structure.values.constants.InvalidValue
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

    override fun visitAssignmentOp(ctx: VoidParser.AssignmentOpContext?): Value? {
        return ctx ?. run {
            val target = ctx.logicalExpression() ?. let { getValue(it) }
            val source = ctx.valueExpression() ?. let { getValue(it) }

            Nullable.zip(target, source) { t, s -> BinaryOperator(t, s, BinaryOperator.Op.Assign, ctx) }
        }
    }

    override fun visitLogicalTopOp(ctx: VoidParser.LogicalTopOpContext?): Value? {
        return ctx ?. run {
            val arg1 = ctx.ifElseOperatorExpression() ?. let { getValue(it) }
            val arg2 = ctx.logicalTopExpression() ?. let { getValue(it) }
            val opC = ctx.logicalTopOperator()
            val op = opC ?. LAnd() ?. let { BinaryOperator.Op.LAnd } ?:
            opC ?. LOr() ?. let { BinaryOperator.Op.LOr }

            Nullable.zip(arg1, arg2, op) { a1, a2, o -> BinaryOperator(a1, a2, o, ctx) }
        }
    }

    override fun visitIfElseOp(ctx: VoidParser.IfElseOpContext?): Value? {
        return ctx ?. run {
            val condition = ctx.logicalExpression() ?. let { getValue(it) }
            val values = ctx.valueExpression() ?. mapNotNull { v -> v ?. let { getValue(v) } } ?. let { if (it.size == 2) it else null }

            Nullable.zip(condition, values) { c, v -> run {
                val tV = v[0]
                val fV = v[1]
                IfElseOperator(c, tV, fV, ctx)
            } }
        }
    }

    override fun visitLogicalOp(ctx: VoidParser.LogicalOpContext?): Value? {
        return ctx ?. run {
            val args = ctx.binaryExpression() ?. mapNotNull { a -> a ?. let { getValue(a)} }

            args ?. count() ?. let { if (it == 2) it else null } ?. run {
                val arg1 = args[0]
                val arg2 = args[1]

                val opC = ctx.logicalOperator()
                val op = opC ?. Eq() ?. let { BinaryOperator.Op.Eq } ?:
                        opC ?. NotEq() ?. let { BinaryOperator.Op.Neq } ?:
                        opC ?. Lt() ?. let { BinaryOperator.Op.Lt } ?:
                        opC ?. Gt() ?. let { BinaryOperator.Op.Gt } ?:
                        opC ?. Leq() ?. let { BinaryOperator.Op.Leq } ?:
                        opC ?. Geq() ?. let { BinaryOperator.Op.Geq }

                Nullable.zip(arg1, arg2, op) { a1, a2, o -> BinaryOperator(a1, a2, o, ctx) }
            }
        }
    }

    override fun visitBinaryOp(ctx: VoidParser.BinaryOpContext?): Value? {
        return ctx ?. run {
            val arg1 = ctx.shiftExpression() ?. let { getValue(it) }
            val arg2 = ctx.binaryExpression() ?. let { getValue(it) }
            val opC = ctx.binaryOperator()
            val op = opC ?. And() ?. let { BinaryOperator.Op.And } ?:
                    opC ?. Or() ?. let { BinaryOperator.Op.Or } ?:
                    opC ?. Xor() ?. let { BinaryOperator.Op.Xor }

            Nullable.zip(arg1, arg2, op) { a1, a2, o -> BinaryOperator(a1, a2, o, ctx) }
        }
    }

    override fun visitShiftOp(ctx: VoidParser.ShiftOpContext?): Value? {
        return ctx ?. run {
            val arg1 = ctx.additiveExpression() ?. let { getValue(it) }
            val arg2 = ctx.shiftExpression() ?. let { getValue(it) }
            val opC = ctx.shiftOperator()
            val op = opC ?. Lt() ?. count { it != null } ?. let { if (it > 0) it else null } ?. let { BinaryOperator.Op.LShift } ?:
                    opC ?. Gt() ?. count { it != null } ?. let { if (it > 0) it else null } ?. let { BinaryOperator.Op.RShift }

            Nullable.zip(arg1, arg2, op) { a1, a2, o -> BinaryOperator(a1, a2, o, ctx) }
        }
    }

    override fun visitAdditiveOp(ctx: VoidParser.AdditiveOpContext?): Value? {
        return ctx ?. run {
            val arg1 = ctx.multiplicativeExpression() ?. let { getValue(it) }
            val arg2 = ctx.additiveExpression() ?. let { getValue(it) }
            val opC = ctx.additiveOperator()
            val op = opC ?. Plus() ?. let { BinaryOperator.Op.Add } ?:
                    opC ?. Minus() ?. let { BinaryOperator.Op.Sub }

            Nullable.zip(arg1, arg2, op) { a1, a2, o -> BinaryOperator(a1, a2, o, ctx) }
        }
    }

    override fun visitMultiplicativeOp(ctx: VoidParser.MultiplicativeOpContext?): Value? {
        return ctx ?. run {
            val arg1 = ctx.castExpression() ?. let { getValue(it) }
            val arg2 = ctx.multiplicativeExpression() ?. let { getValue(it) }
            val opC = ctx.multOperator()
            val op = opC ?. Mult() ?. let { BinaryOperator.Op.Mul } ?:
                opC ?. Divide() ?. let { BinaryOperator.Op.Div } ?:
                opC ?. Modulo() ?. let { BinaryOperator.Op.Mod }

            Nullable.zip(arg1, arg2, op) { a1, a2, o -> BinaryOperator(a1, a2, o, ctx) }
        }
    }

    override fun visitAsCast(ctx: VoidParser.AsCastContext?): Value? {
        return ctx ?. run {
            val value = ctx.castExpression() ?. let { getValue(it) }
            val type = ctx.typeExpression() ?. let { typeVisitor.getType(it) }

            Nullable.zip(value, type) { v, t -> ValueCast(v, t, ctx) }
        }
    }

    override fun visitCCast(ctx: VoidParser.CCastContext?): Value? {
        return ctx ?. run {
            val value = ctx.valueExpression() ?. let { getValue(it) }
            val type = ctx.typeExpression() ?. let { typeVisitor.getType(it) }

            Nullable.zip(value, type) { v, t -> ValueCast(v, t, ctx) }
        }
    }

    override fun visitUnaryOp(ctx: VoidParser.UnaryOpContext?): Value? {
        return ctx ?. run {
            val value = ctx.unaryExpression() ?. let { getValue(it) }
            val opC = ctx.unaryOperator()
            val op = opC ?. PlusPlus() ?. let { UnaryOperator.Op.Inc } ?:
                    opC ?. MinusMinus() ?. let { UnaryOperator.Op.Dec } ?:
                    opC ?. Not() ?. let { UnaryOperator.Op.Not } ?:
                    opC ?. Neg() ?. let { UnaryOperator.Op.Neg }

            Nullable.zip(value, op) { v, o -> UnaryOperator(v, o, false, ctx) }
        }
    }

    override fun visitPostfixOp(ctx: VoidParser.PostfixOpContext?): Value? {
        return ctx ?. run {
            val value = ctx.postfixExpression() ?. let { getValue(it) }
            val opC = ctx.postfixOperator()
            val op = opC ?. PlusPlus() ?. let { UnaryOperator.Op.Inc } ?:
                    opC ?. MinusMinus() ?. let { UnaryOperator.Op.Dec }

            Nullable.zip(value, op) { v, o -> UnaryOperator(v, o, true, ctx) }
        }
    }

    override fun visitFunctionCall(ctx: VoidParser.FunctionCallContext?): Value? {
        return ctx ?. run {
            val function = ctx.accessExpression() ?. let { getValue(it) }
            val args = ctx.functionCallArgs() ?. valueExpression() ?. mapNotNull { v -> v ?. let { getValue(v) } }
            Nullable.zip(function, args) { f, a -> FunctionInvoke(f, a, ctx) }
        }
    }

    override fun visitMemberAccess(ctx: VoidParser.MemberAccessContext?): Value? {
        return ctx ?. run {
            val source = ctx.accessExpression() ?. let { getValue(it) }
            val member = ctx.variableExpression() ?. identifier() ?. text
            Nullable.zip(source, member) { s, m -> MemberAccess(s, m, ctx) }
        }
    }

    override fun visitCtorInvoke(ctx: VoidParser.CtorInvokeContext?): Value? {
        return ctx ?. run {
            val type = ctx.typeExpression() ?. let { typeVisitor.getType(it) } ?: TypeInvalid(ctx)
            val args = ctx.ctorInit() ?. valueExpression() ?. mapNotNull { v -> v ?. let { getValue(v) } }

            args ?. run { ConstructorInvoke(type, args, ctx) }
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
                InvalidValue(ctx)
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
        return ctx ?. SimpleString() ?.let {
            val t = it.text
            StringValue(t.substring(1, t.count() - 1), ctx)
        }
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
                    val type = it.typeExpression() ?. let { t -> typeVisitor.getType(t) } ?: TypeAuto(it)
                    val value = it.valueExpression() ?. let { v -> getValue(v) }

                    ObjectValue.ObjectSubDecl(type, name, value)
                } } ?: run {
                    errorLogger.structureError(it, "invalid member")
                }
            } }
            ObjectValue(members, ctx)
        }
    }
}