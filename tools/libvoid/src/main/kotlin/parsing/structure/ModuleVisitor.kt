package parsing.structure

import VoidParser
import VoidParserBaseVisitor

class ModuleVisitor(dataSource: String? = null): VoidParserBaseVisitor<Unit>() {
    val errorLogger = ErrorLogger(dataSource ?: "input")

    private var module: Module? = null

    private val pack = VisitorPack(errorLogger)

    fun getModule(): Module {
        return module ?: Module("main")
    }

    override fun visitModuleDefinition(ctx: VoidParser.ModuleDefinitionContext) {
        if (module != null) {
            errorLogger.structureError(ctx, "module was not the first expression in the file")
            return
        }
        ctx.identifier().Name() ?. also {
            module = Module(it.text)
        } ?: run {
            errorLogger.structureError(ctx, "missing module name")
        }
    }

    override fun visitImportDeclaration(ctx: VoidParser.ImportDeclarationContext) {
        val m = requireModule()
        ctx.identifier().Name() ?. also {
            m.import(it.text)
        } ?: run {
            errorLogger.structureError(ctx,"missing module name")
        }
    }

    override fun visitVarDeclaration(ctx: VoidParser.VarDeclarationContext) {
        val variableDeclaration = pack.getDeclaration(ctx)
        requireModule().registerVariableDecl(variableDeclaration)
    }

    override fun visitFunctionDefinition(ctx: VoidParser.FunctionDefinitionContext) {
        val functionDeclaration = pack.getFunction(ctx)
        requireModule().registerFunction(functionDeclaration)
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
}