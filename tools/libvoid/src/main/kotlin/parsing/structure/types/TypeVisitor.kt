package parsing.structure.types

import VoidParserBaseVisitor
import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.ErrorLogger
import parsing.structure.variables.SimpleVariableDeclaration
import parsing.structure.variables.VariableDeclarationVisitor

class TypeVisitor(private val errorLogger: ErrorLogger, vV: VariableDeclarationVisitor? = null): VoidParserBaseVisitor<Type?>() {
    private val variableDeclarationVisitor = vV ?: VariableDeclarationVisitor(errorLogger, this)

    fun getType(ctx: ParserRuleContext): Type {
        return visit(ctx) ?: run {
            errorLogger.structureError(ctx, "type expected")
            TypeInvalid(ctx)
        }
    }

    override fun visitTypeName(ctx: VoidParser.TypeNameContext?): Type? {
        return ctx?.identifier()?.text?.let { TypeName(it, ctx) }
    }

    override fun visitTypeAccess(ctx: VoidParser.TypeAccessContext?): Type? {
        return ctx?.run {
            val parent = getType(ctx.typeTemplate())
            val child = getType(ctx.typeSubExpression())
            TypeAccess(parent, child, ctx)
        }
    }

    override fun visitTypeTemplate(ctx: VoidParser.TypeTemplateContext?): Type? {
        return ctx?.run {
            val base = getType(ctx.typeName())
            val args = ctx.typeExpression()?.map { it ?. let { getType(it) } ?: TypeInvalid(ctx) }

            if (args == null || args.isEmpty())
                base
            else
                TypeTemplate(base, args, ctx)
        }
    }

    override fun visitLambdaObjectType(ctx: VoidParser.LambdaObjectTypeContext?): Type? {
        return ctx?.run {
            val members = ctx.cStyleVarDeclaration()?.mapNotNull { v -> v?.let {
                val memberDecl = variableDeclarationVisitor.getDeclaration(v) as? SimpleVariableDeclaration
                memberDecl?.declaredVariables
            } } ?: listOf()
            LambdaObjectType(ctx, members.flatten())
        }
    }
}