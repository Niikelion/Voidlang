package parsing

import VoidParserBaseVisitor
import br.com.devsrsouza.eventkt.scopes.LocalEventScope
import parsing.structure.Module
import VoidParser
import parsing.structure.variables.VariableDeclarationVisitor

class ParserVisitor(dataSource: String? = null): VoidParserBaseVisitor<Unit>() {
    val onError = LocalEventScope()

    private val source = dataSource ?: "input"
    private var module: Module? = null

    private val variableVisitor = VariableDeclarationVisitor()

    fun getModule(): Module {
        return module ?: Module("main")
    }

    override fun visitModuleDefinition(ctx: VoidParser.ModuleDefinitionContext) {
        if (module != null) {
            structureError(ctx, "module was not the first expression in the file")
            return
        }
        ctx.identifier().Name() ?. also {
            module = Module(it.text)
        } ?: run {
            structureError(ctx, "missing module name")
        }
    }

    override fun visitImportDeclaration(ctx: VoidParser.ImportDeclarationContext) {
        val m = requireModule()
        ctx.identifier().Name() ?. also {
            m.import(it.text)
        } ?: run {
            structureError(ctx,"missing module name")
        }
    }

    override fun visitVarDeclaration(ctx: VoidParser.VarDeclarationContext) {
        val variableDeclaration = variableVisitor.visit(ctx)
        variableDeclaration ?. also { requireModule().registerVariableDecl(it) }
    }

    override fun visitFunctionDefinition(ctx: VoidParser.FunctionDefinitionContext) {
        //
    }

    override fun visitClassDefinition(ctx: VoidParser.ClassDefinitionContext) {
        //
    }

    override fun visitTraitDefinition(ctx: VoidParser.TraitDefinitionContext) {
        //
    }

    private fun requireModule(): Module {
        return module ?: run {
            module = Module("main")
            return module!!
        }
    }

    private fun structureError(ctx: VoidParser.TopLevelContext, msg: String) {
        onError.publish(
            StructureError(
                ctx.getStart().line,
                ctx.getStart().charPositionInLine,
                source,
                msg
            )
        )
    }
}