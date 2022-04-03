package parsing.structure.types

import VoidParserBaseVisitor
import parsing.structure.ErrorLogger
import parsing.structure.variables.SimpleVariableDeclaration
import parsing.structure.variables.VariableDeclarationVisitor

class TypeVisitor(private val errorLogger: ErrorLogger, vV: VariableDeclarationVisitor? = null): VoidParserBaseVisitor<Type?>() {
    private val variableDeclarationVisitor = vV ?: VariableDeclarationVisitor(errorLogger, this)

    fun getType(ctx: VoidParser.TypeExpressionContext?): Type {
        return visit(ctx) ?: TypeInvalid()
    }

    override fun visitTypeName(ctx: VoidParser.TypeNameContext?): Type? {
        return ctx?.identifier()?.text?.let { TypeName(it) }
    }

    override fun visitTypeAccess(ctx: VoidParser.TypeAccessContext?): Type? {
        return ctx?.run {
            val parent = visit(ctx.typeTemplate()) ?: TypeInvalid()
            val child = visit(ctx.typeSubExpression()) ?: TypeInvalid()
            TypeAccess(parent, child)
        }
    }

    override fun visitTypeTemplate(ctx: VoidParser.TypeTemplateContext?): Type? {
        return ctx?.run {
            val base = visit(ctx.typeName()) ?: TypeInvalid()
            val args = ctx.typeExpression()?.map { it?.let { visit(it) } ?: TypeInvalid() }

            if (args == null || args.isEmpty())
                base
            else
                TypeTemplate(base, args)
        }
    }

    override fun visitLambdaObjectType(ctx: VoidParser.LambdaObjectTypeContext?): Type? {
        return ctx?.run {
            val members = ctx.cStyleVarDeclaration()?.mapNotNull { v -> v?.let {
                val memberDecl = variableDeclarationVisitor.visit(v) as? SimpleVariableDeclaration
                memberDecl?.declaredVariables
            } } ?: listOf()
            LambdaObjectType(members.flatten())
        }
    }
}