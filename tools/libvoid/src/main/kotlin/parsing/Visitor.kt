package parsing

import VoidError
import VoidParserBaseListener
import br.com.devsrsouza.eventkt.scopes.LocalEventScope
import parsing.structure.Module
import parsing.structure.Token

class StructureError(
    line: Int,
    pos: Int,
    source: String? = null,
    val msg: String
): VoidError(line, pos, source) {
    override fun getErrorMsg(): String {
        return "structure error - $msg"
    }
}

class Visitor(dataSource: String? = null): VoidParserBaseListener() {
    private val source = dataSource ?: "input"
    val onError = LocalEventScope();

    private val symbolStack = ArrayDeque<Token>()

    private var module: Module? = null

    fun getModule(): Module {
        if (module == null)
            module = Module("main")

        return module!!
    }

    override fun exitTopLevelDeclaration(ctx: VoidParser.TopLevelDeclarationContext?) {
        ctx!!

        val module = getModule()
        val top = if (symbolStack.isNotEmpty()) symbolStack.last() else null
    }

    override fun exitImportDeclaration(ctx: VoidParser.ImportDeclarationContext?) {
        ctx!!

        val module = getModule()
        module.imports.add(ctx.importExpr().identifier().text)
    }

    override fun exitModuleDefinition(ctx: VoidParser.ModuleDefinitionContext?) {
        ctx!!

        if (module != null)
            onError.publish(StructureError(ctx.start.line, ctx.start.charPositionInLine, source, "module must be the first expression in the file"))
        else
            module = Module(ctx.moduleDef().identifier().text)
    }

    private fun peekSymbols(n: Int): Array<Token>? {
        return if (symbolStack.size >= n) symbolStack.drop()
    }

    private fun peekSymbol(): Token? {
        return symbolStack.lastOrNull()
    }
}