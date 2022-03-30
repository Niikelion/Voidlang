package parsing

import VoidError
import VoidParserBaseListener
import br.com.devsrsouza.eventkt.scopes.LocalEventScope
import parsing.structure.Module
import parsing.structure.Function
import parsing.structure.variables.CStyleVariable
import parsing.structure.expressions.Expression
import parsing.structure.types.Type
import parsing.structure.types.TypeName
import parsing.structure.values.Value

class StructureError(
    line: Int,
    pos: Int,
    source: String? = null,
    private val msg: String
): VoidError(line, pos, source) {
    override fun getErrorMsg(): String {
        return "structure error - $msg"
    }
}

private class FunctionSig {
    var ret: Type? = null
    var args = mutableListOf<Pair<Type, String>>()
}

private class CStyleVarSubDecl(val name: String) {
    var value: Value? = null
}

private class VariableList {
    val variables = mutableListOf<CStyleVariable>()
}

private typealias Handler = (Any) -> Unit
private typealias HandlerCompanion = () -> Any

class Visitor(dataSource: String? = null): VoidParserBaseListener() {
    private val source = dataSource ?: "input"
    val onError = LocalEventScope()

    private val symbolHandlersStack = ArrayDeque<Pair<Handler, HandlerCompanion?>>()

    private var module: Module? = null

    fun getModule(): Module {
        if (module == null)
            module = Module("main")

        return module!!
    }

    override fun enterTopLevelDeclaration(ctx: VoidParser.TopLevelDeclarationContext?) {
        ctx!!
        val module = getModule()
        if (ctx.declaration().commonDeclaration().functionDefinition() != null)
            pushHandler({ token -> run {
                val func = token as? Function
                func ?. run { module.registerFunction(func) }
            } })
        if (ctx.declaration().commonDeclaration().varDeclaration() != null)
            pushHandler({ token -> run {
                val variable = token as? CStyleVariable
                variable ?. run { module.registerVariable(variable) }
            } })
    }

    override fun exitTopLevelDeclaration(ctx: VoidParser.TopLevelDeclarationContext?) {
        ctx!!

        if (ctx.declaration().commonDeclaration().functionDefinition() != null)
            popHandler()
        if (ctx.declaration().commonDeclaration().varDeclaration() != null)
            popHandler()
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

    override fun enterArrowFunctionDef(ctx: VoidParser.ArrowFunctionDefContext?) {
        ctx!!

        val name = ctx.functionDefSignature().identifier().text
        enterFunction(name)
    }

    override fun enterCstyleFunctionDef(ctx: VoidParser.CstyleFunctionDefContext?) {
        ctx!!

        val name = ctx.functionDefSignature().identifier().text
        enterFunction(name)
    }

    override fun enterFunctionDefSignature(ctx: VoidParser.FunctionDefSignatureContext?) {
        ctx!!

        val functionSig = FunctionSig()

        pushHandler({ token ->
            run {
                functionSig.ret = token as? Type
                functionSig.ret ?. run { replaceHandler({ token ->
                    run {
                        val v = token as? CStyleVariable
                        v ?. run { functionSig.args.add(Pair(v.type!!, v.name)) }
                    }
                }, { functionSig }) }
            }
        }, {functionSig})
    }

    override fun exitFunctionDefSignature(ctx: VoidParser.FunctionDefSignatureContext?) {
        ctx!!

        val functionSig = getHandlerCompanion() ?. let { it() as FunctionSig }
        popHandler()
        functionSig ?. run { submit(functionSig) }
    }

    override fun exitArrowFunctionDef(ctx: VoidParser.ArrowFunctionDefContext?) {
        ctx!!

        exitFunction()
    }

    override fun exitCstyleFunctionDef(ctx: VoidParser.CstyleFunctionDefContext?) {
        ctx!!

        exitFunction()
    }

    override fun enterArgumentDef(ctx: VoidParser.ArgumentDefContext?) {
        ctx!!
        pushHandler({ token -> run {
            val type = token as? Type
            type ?. run {
                replaceHandler({ token -> run {
                    val subDecl = token as? CStyleVarSubDecl
                    subDecl ?. run {
                        val variable = CStyleVariable(subDecl.name, type, subDecl.value)
                        replaceHandler({ }, { variable })
                    }
                } })
            }
        } })
    }

    override fun exitArgumentDef(ctx: VoidParser.ArgumentDefContext?) {
        ctx!!
        val variable = getCompanion() as? CStyleVariable
        popHandler()
        variable ?. run { submit(variable) }
    }

    override fun enterVarSubDeclaration(ctx: VoidParser.VarSubDeclarationContext?) {
        ctx!!

        val typeDecl = CStyleVarSubDecl(ctx.identifier().text)

        pushHandler({ token -> run {
            val value = token as? Value
            value ?. run {
                typeDecl.value = value
            }
        }}, { typeDecl })
    }

    override fun exitVarSubDeclaration(ctx: VoidParser.VarSubDeclarationContext?) {
        ctx!!

        val varDecl = getCompanion() as? CStyleVarSubDecl
        popHandler()

        varDecl ?. run { submit(varDecl) }
    }

    override fun enterCStyleVarDeclaration(ctx: VoidParser.CStyleVarDeclarationContext?) {
        ctx!!

        val list = VariableList()

        pushHandler({ token -> run {
            val type = token as? Type
            type ?. run {
                replaceHandler({ token -> run {
                    val decl = token as? CStyleVarSubDecl
                    decl ?. run { list.variables.add(CStyleVariable(decl.name, type, decl.value)) }
                } }, { list })
            }
        } }, { list })
    }

    override fun exitCStyleVarDeclaration(ctx: VoidParser.CStyleVarDeclarationContext?) {
        ctx!!

        val list = getCompanion() as? VariableList
        popHandler()
        list ?. run {
            for (variable in list.variables)
                submit(variable)
        }
    }

    override fun exitTypeName(ctx: VoidParser.TypeNameContext?) {
        ctx!!

        submit(TypeName(ctx.identifier().text))
    }

    private fun enterFunction(name: String) {
        pushHandler({ sig ->
            run {
                val signature = sig as? FunctionSig
                signature ?. run {
                    val func = Function(name, signature.ret ?: TypeName("void"), signature.args)
                    replaceHandler({ token -> run {
                        val expression = token as? Expression
                        expression ?. run { func.body.add(expression) }
                    } }, { func })
                }
            }
        })
    }

    private fun exitFunction() {
        val func = getCompanion() as? Function
        popHandler()
        func ?. run { submit(func) }
    }

    private fun submit(token: Any) {
        if (symbolHandlersStack.isNotEmpty())
            getHandler()(token)
    }

    private fun getCompanion(): Any? {
        return getHandlerCompanion() ?. let { it() }
    }

    private fun getHandlerCompanion(): HandlerCompanion? {
        return symbolHandlersStack.last().second
    }

    private fun getHandler(): Handler {
        return symbolHandlersStack.last().first
    }

    private fun popHandler() {
        symbolHandlersStack.removeLast()
    }

    private fun pushHandler(handler: Handler, companion: HandlerCompanion? = null) {
        symbolHandlersStack.addLast(Pair(handler, companion))
    }

    private fun replaceHandler(handler: Handler, companion: HandlerCompanion? = null) {
        popHandler()
        pushHandler(handler, companion)
    }
}