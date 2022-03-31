package parsing.structure.types

import VoidParserBaseVisitor
class TypeVisitor: VoidParserBaseVisitor<Type>() {
    fun getType(ctx: VoidParser.TypeExpressionContext?): Type {
        return visit(ctx) ?: TypeInvalid()
    }

    override fun visitTypeName(ctx: VoidParser.TypeNameContext?): Type? {
        return ctx ?. let { TypeName(it.identifier().text) }
    }

    override fun visitTypeAccess(ctx: VoidParser.TypeAccessContext?): Type? {
        return ctx ?. run {
            val parent = visitTypeTemplate(ctx.typeTemplate()) ?: TypeInvalid()
            val child = visitTypeExpression(ctx.typeExpression()) ?: TypeInvalid()
            return TypeAccess(parent, child)
        }
    }

    override fun visitTypeTemplate(ctx: VoidParser.TypeTemplateContext?): Type? {
        return ctx ?. run {
            val base = visitTypeName(ctx.typeName()) ?: TypeInvalid()
            val args = ctx.typeExpression() ?. map { it ?. let { visitTypeExpression(it) } ?: TypeInvalid() }

            return if (args == null || args.isEmpty())
                base
            else
                TypeTemplate(base, args)
        }
    }
}