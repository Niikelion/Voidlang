package parsing.structure.variables

import VoidParserBaseVisitor
import parsing.structure.ErrorLogger
import parsing.structure.types.Type
import parsing.structure.types.TypeVisitor
import parsing.structure.values.Value
import parsing.structure.values.ValueVisitor

class VariableDeclarationVisitor(private val errorLogger: ErrorLogger): VoidParserBaseVisitor<VariableDeclaration>() {
    private val typeVisitor = TypeVisitor()
    private val valueVisitor = ValueVisitor()

    override fun visitCStyleVarDeclaration(ctx: VoidParser.CStyleVarDeclarationContext?): VariableDeclaration? {
        return ctx ?. run {
            val type = typeVisitor.getType(ctx.typeExpression())
            val subdecls = ctx.varSubDeclaration().mapNotNull { v ->
                    run {
                        val name = v.identifier().Name()?.text
                        val value = v.varDeclInit()?.let {
                            valueVisitor.getValue(it.valueExpression()) ?:
                            constructorInitialization(type, it.declInit())
                        }
                        name?.let { CStyleVariableDeclaration.SubDecl(name, value) } ?: run {
                            errorLogger.structureError(v, "missing variable name")
                            null
                        }
                    }
                }
            return CStyleVariableDeclaration(type, subdecls)
        }
    }

    private fun constructorInitialization(type: Type, ctx: VoidParser.DeclInitContext?): Value? {
        return ctx ?. run {
                errorLogger.structureError(ctx, "this variable initialization is not supported")
            null
        }
    }
}