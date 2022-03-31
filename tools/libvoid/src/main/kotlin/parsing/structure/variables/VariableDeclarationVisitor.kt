package parsing.structure.variables

import VoidParserBaseVisitor
import parsing.structure.types.TypeVisitor
import parsing.structure.values.ValueVisitor

class VariableDeclarationVisitor: VoidParserBaseVisitor<VariableDeclaration>() {
    private val typeVisitor = TypeVisitor()
    private val valueVisitor = ValueVisitor()

    override fun visitCStyleVarDeclaration(ctx: VoidParser.CStyleVarDeclarationContext?): VariableDeclaration? {
        return ctx ?. run {
            val type = typeVisitor.getType(ctx.typeExpression())
            val subdecls = //error, invalid argument def
                ctx.varSubDeclaration().mapNotNull { v ->
                    run {
                        val name = v.identifier().Name()?.text
                        val value = v.varDeclInit()?.let {
                            valueVisitor.getValue(it.valueExpression())
                                ?: null//TODO("initialization by constructor call not supported")
                        }
                        name?.let { CStyleVariableDeclaration.SubDecl(name, value) } ?: run {
                            //TODO("throw error: incomplete sub-declaration")
                            null
                        }
                    }
                }
            return CStyleVariableDeclaration(type, subdecls)
        }
    }
}