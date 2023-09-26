package void.compiler

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.NoOpCliktCommand
import com.github.ajalt.clikt.core.subcommands
import com.github.ajalt.clikt.parameters.options.multiple
import com.github.ajalt.clikt.parameters.options.option
import com.github.ajalt.clikt.parameters.types.file
import parsing.Parser

class App {
    private val files = mutableListOf<String>()

    fun run() {
        val parser = Parser()

//        val modules = if (files.isNotEmpty())
//            files.mapNotNull { file -> parser.parseFile(file) }
//        else {
//            listOf(parser.parse(System.`in`))
//        }
//
//        parser.printErrors()
//        parser.clearErrors()
//        println("Modules:")
//        println(modules.joinToString(separator = "\n-----\n") { module -> module.readable() })
    }

    fun addFile(file: String) {
        files.add(file)
    }
}

abstract class CompilerCommand(
    help: String = ""
): CliktCommand(
    help = help
) {
    val verbose by option("-v", "--verbose")
}

class Compile: CompilerCommand(help="compiles given sources") {
    override fun run() {
        TODO("Not implemented yet")
    }
}

class Parse: CompilerCommand(help="parses given sources") {
    private val files by option("-f","--files").file(mustExist = true, mustBeReadable = true, canBeSymlink = false, canBeDir = false).multiple()

    override fun run() {
        val app = App()
        for (file in files)
            app.addFile(file.absolutePath)
        app.run()
    }
}

class VoidC : NoOpCliktCommand()

fun main(args: Array<String>) = VoidC().subcommands(Compile(), Parse()).main(args)