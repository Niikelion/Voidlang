package parsing.structure

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.expressions.ExpressionVisitor
import parsing.structure.functions.FunctionVisitor
import parsing.structure.types.TypeVisitor
import parsing.structure.values.ValueVisitor
import parsing.structure.variables.VariableDeclarationVisitor

class VisitorPack(val errorLogger: ErrorLogger) {
    private val valueVisitor: ValueVisitor = ValueVisitor(errorLogger, this)
    private val variableVisitor: VariableDeclarationVisitor = VariableDeclarationVisitor(errorLogger, this)
    private val typeVisitor: TypeVisitor = TypeVisitor(errorLogger, this)
    private val functionVisitor: FunctionVisitor = FunctionVisitor(errorLogger, this)
    private val expressionVisitor: ExpressionVisitor = ExpressionVisitor(errorLogger, this)

    fun getValue(ctx: ParserRuleContext) = valueVisitor.getValue(ctx)
    fun getDeclaration(ctx: ParserRuleContext) = variableVisitor.getDeclaration(ctx)
    fun getType(ctx: ParserRuleContext) = typeVisitor.getType(ctx)
    fun getFunction(ctx: ParserRuleContext) = functionVisitor.getFunction(ctx)
    fun getFunctionBody(ctx: VoidParser.FunctionBodyContext) = expressionVisitor.getFunctionBody(ctx)
}