package parsing.structure.variables

import VoidParserBaseVisitor
import parsing.structure.ErrorLogger
import parsing.structure.types.Type
import parsing.structure.types.TypeAuto
import parsing.structure.types.TypeInvalid
import parsing.structure.types.TypeVisitor
import parsing.structure.values.Value
import parsing.structure.values.ValueVisitor

class VariableDeclarationVisitor(private val errorLogger: ErrorLogger, tV: TypeVisitor? = null, vV: ValueVisitor? = null): VoidParserBaseVisitor<VariableDeclaration?>() {
    private val typeVisitor = tV ?: TypeVisitor(errorLogger, this)
    private val valueVisitor = vV ?: ValueVisitor(errorLogger)

    override fun visitCStyleVarDeclaration(ctx: VoidParser.CStyleVarDeclarationContext?): VariableDeclaration? {
        return ctx ?. run {
            val type = typeVisitor.getType(ctx.typeExpression(), ctx)
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
            val value = valueVisitor.getValue(ctx.valueExpression())
            value?.let {
                VariableTupleDeconstruction(members, value)
            } ?: run {
                errorLogger.structureError(ctx, "missing tuple value assignment")
            }
        }
    }

    private fun constructorInitialization(type: Type, ctx: VoidParser.DeclInitContext?): Value? {
        return ctx ?. run {
            //TODO
            errorLogger.structureError(ctx, "this variable initialization is not supported")
        }
    }

    private fun handleSubDeclaration(type: Type, ctx: VoidParser.VarSubDeclarationContext?) : SimpleVariableDeclaration.SubDecl? {
        return ctx?.run {
            val name = ctx.identifier()?.Name()?.text
            val value = ctx.varDeclInit()?.let {
                valueVisitor.getValue(it.valueExpression()) ?: constructorInitialization(type, it.declInit())
            }
            name?.let { SimpleVariableDeclaration.SubDecl(name, value) } ?: run {
                errorLogger.structureError(ctx, "missing variable name")
            }
        }
    }
}