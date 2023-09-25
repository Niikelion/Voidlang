package parsing.structure.variables

import VoidParserBaseVisitor
import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.ErrorLogger
import parsing.structure.VisitorPack
import parsing.structure.types.Type
import parsing.structure.types.TypeAuto
import parsing.structure.types.TypeInvalid
import parsing.structure.values.ConstructorInvoke
import parsing.structure.values.PiecewiseInitialization
import parsing.structure.values.Value
import parsing.structure.values.constants.InvalidValue

class VariableDeclarationVisitor(
    private val errorLogger: ErrorLogger,
    private val p: VisitorPack
): VoidParserBaseVisitor<VariableDeclaration?>() {

    fun getDeclaration(ctx: ParserRuleContext): VariableDeclaration {
        return visit(ctx) ?: run {
            errorLogger.structureError(ctx, "declaration missing")
            InvalidVariableDeclaration()
        }
    }

    override fun visitCStyleVarDeclaration(ctx: VoidParser.CStyleVarDeclarationContext?): VariableDeclaration? {
        return ctx ?. run {
            val type = p.getType(ctx.typeExpression())
            val subdecls = ctx.varSubDeclaration()?.mapNotNull { v -> handleSubDeclaration(type, v) } ?: listOf()
            SimpleVariableDeclaration(type, subdecls)
        }
    }

    override fun visitExtendedCStyleVarDeclaration(ctx: VoidParser.ExtendedCStyleVarDeclarationContext?): VariableDeclaration? {
        return ctx?.run {
            val type = ctx.Var()?.let { TypeAuto(ctx) } ?: run {
                errorLogger.structureError(ctx, "invalid lambda object type")
                TypeInvalid(ctx)
            }
            val subdecls = ctx.varSubDeclaration()?.mapNotNull { v -> handleSubDeclaration(type, v) } ?: listOf()
            SimpleVariableDeclaration(type, subdecls)
        }
    }

    override fun visitDeconstructionVarDeclaration(ctx: VoidParser.DeconstructionVarDeclarationContext?): VariableDeclaration? {
        return ctx?.tupleDeconstructionDecl()?.let {
            val deconstructionDecl = it
            val members = deconstructionDecl.identifier()?.mapNotNull { m ->
                m?.Name()?.text ?: run {
                    errorLogger.structureError(ctx, "missing tuple member name")
                }
            } ?: listOf()
            val value = p.getValue(ctx.valueExpression())
            VariableTupleDeconstruction(members, value)
        }
    }

    private fun indirectInitialization(type: Type, ctx: VoidParser.DeclInitContext): Value {
        return ctx.ctorInit() ?. let { constructorInitialization(type, it) } ?:
        ctx.piecewiseInit() ?. let { piecewiseInitialization(type, it) } ?: run {
            errorLogger.structureError(ctx, "this variable initialization is not supported")
            return InvalidValue(ctx)
        }
    }

    private fun constructorInitialization(type: Type, ctx: VoidParser.CtorInitContext): Value {
        val args = ctx.valueExpression().mapNotNull {
            it ?. let { p.getValue(it) } ?: run {
                errorLogger.structureError(ctx, "value expression expected")
            }
        }
        return ConstructorInvoke(type, args, ctx)
    }

    private fun piecewiseInitialization(type: Type, ctx: VoidParser.PiecewiseInitContext): Value {
        val members = ctx.piecewiseSubInit().mapNotNull {
            v -> v ?. identifier() ?. text ?. let { VarSubDecl(it, p.getValue(v.valueExpression())) } ?: run {
                errorLogger.structureError(ctx, "invalid member initializer")
            }
        }

        return PiecewiseInitialization(type, members, ctx)
    }

    private fun handleSubDeclaration(type: Type, ctx: VoidParser.VarSubDeclarationContext?) : VarSubDecl? {
        return ctx?.run {
            val name = ctx.identifier()?.Name()?.text
            val value = ctx.varDeclInit()?.let { it ->
                it.valueExpression() ?. let { i -> p.getValue(i)} ?:
                it.declInit() ?. let { i -> indirectInitialization(type, i) } ?:
                InvalidValue(it)
            }
            name?.let { VarSubDecl(name, value) } ?: run {
                errorLogger.structureError(ctx, "missing variable name")
            }
        }
    }
}