package parsing

import VoidError
import VoidLexer
import VoidParser
import br.com.devsrsouza.eventkt.listen
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import org.antlr.v4.runtime.CharStream
import org.antlr.v4.runtime.CharStreams
import org.antlr.v4.runtime.CommonTokenStream
import org.antlr.v4.runtime.tree.ParseTreeWalker
import java.io.File

class Parser() {
    val errors = mutableListOf<VoidError>()

    fun clearErrors() {
        errors.clear()
    }

    fun printErrors() {
        println(errors.joinToString(separator = "\n"))
    }

    fun parse(source: String): parsing.structure.Module {
        return processData(getAntlrParser(CharStreams.fromString(source)))
    }

    fun parseFile(fileName: String): parsing.structure.Module? {
        val file = File(fileName)
        if (!file.exists())
            return null
        return processData(getAntlrParser(CharStreams.fromFileName(file.absolutePath)))
    }

    private fun getAntlrParser(input: CharStream): VoidParser {
        val lexer = VoidLexer(input)
        val tokenStream = CommonTokenStream(lexer)
        val parser = VoidParser(tokenStream)

        lexer.removeErrorListeners()
        parser.removeErrorListeners()

        val sourceName = if (input.sourceName != CharStream.UNKNOWN_SOURCE_NAME) input.sourceName else null

        val errorListener = EventErrorListener(sourceName)
        errorListener.onError.listen<SyntaxError>().onEach { error -> errors.add(error) }.launchIn(GlobalScope)

        lexer.addErrorListener(errorListener)
        parser.addErrorListener(errorListener)

        return parser
    }

    private fun processData(parser: VoidParser, ): parsing.structure.Module {
        val input = parser.input()
        val sourceName = if (parser.sourceName != CharStream.UNKNOWN_SOURCE_NAME) parser.sourceName else null
        val visitor = Visitor(sourceName)
        visitor.onError.listen<StructureError>().onEach { error -> errors.add(error) }.launchIn(GlobalScope)
        ParseTreeWalker.DEFAULT.walk(visitor, input)
        return visitor.getModule()
    }
}