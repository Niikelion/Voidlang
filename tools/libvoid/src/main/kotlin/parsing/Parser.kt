package parsing

import IOError
import VoidError
import VoidLexer
import VoidParser
import org.antlr.v4.runtime.CharStream
import org.antlr.v4.runtime.CharStreams
import org.antlr.v4.runtime.CommonTokenStream
import java.io.File
import java.io.InputStream

class Parser {
    private val errors = mutableListOf<VoidError>()

    fun clearErrors() {
        errors.clear()
    }

    fun getErrors(): List<VoidError> {
        return errors.toList()
    }

    fun printErrors() {
        println(errors.joinToString(separator = "\n"))
    }

//    fun parse(source: String): Module {
//        return processData(getAntlrParser(CharStreams.fromString(source)))
//    }
//
//    fun parse(stream: InputStream): Module {
//        return processData(getAntlrParser(CharStreams.fromStream(stream)))
//    }
//
//    fun parseFile(fileName: String): Module? {
//        val file = File(fileName)
//        if (!file.exists()) {
//            logError(IOError(fileName, "could not open the file"))
//            return null
//        }
//        return processData(getAntlrParser(CharStreams.fromFileName(file.absolutePath)))
//    }

    private fun getAntlrParser(input: CharStream): VoidParser {
        val lexer = VoidLexer(input)
        val tokenStream = CommonTokenStream(lexer)
        val parser = VoidParser(tokenStream)

        lexer.removeErrorListeners()
        parser.removeErrorListeners()

        val sourceName = if (input.sourceName != CharStream.UNKNOWN_SOURCE_NAME) input.sourceName else null

        val errorListener = EventErrorListener(sourceName)
        errorListener.errorLogger.subscribe { error -> logError(error) }

        lexer.addErrorListener(errorListener)
        parser.addErrorListener(errorListener)

        return parser
    }

//    private fun processData(parser: VoidParser): Module {
//        val input = parser.input()
//        val sourceName = if (parser.sourceName != CharStream.UNKNOWN_SOURCE_NAME) parser.sourceName else null
//        val visitor = ModuleVisitor(sourceName)
//        visitor.errorLogger.subscribe { error -> logError(error) }
//        visitor.visit(input)
//        return visitor.getModule()
//    }

    private fun logError(error: VoidError) {
        errors.add(error)
    }
}