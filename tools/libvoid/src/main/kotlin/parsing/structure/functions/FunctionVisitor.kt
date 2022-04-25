package parsing.structure.functions

import parsing.structure.ErrorLogger
import parsing.structure.types.TypeVisitor
import parsing.structure.values.ValueVisitor
import parsing.structure.variables.VariableDeclarationVisitor
import parsing.structure.functions.Function;
import VoidParserBaseVisitor

class FunctionVisitor(private val errorLogger: ErrorLogger, tv: TypeVisitor? = null, vdv: VariableDeclarationVisitor? = null, vv: ValueVisitor? = null): VoidParserBaseVisitor<Function>() {
    val typeVisitor = tv ?: TypeVisitor(errorLogger, vdv)
    val variableVisitor = vdv ?: VariableDeclarationVisitor(errorLogger, tv, vv)
    val valueVisitor = vv ?: ValueVisitor(errorLogger, typeVisitor)

    fun getFunction(ctx: VoidParser.FunctionDefinitionContext?): Function? {
        return null
    }
}