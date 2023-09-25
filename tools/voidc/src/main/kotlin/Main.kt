package void.compiler

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.subcommands
import com.github.ajalt.clikt.parameters.options.flag
import com.github.ajalt.clikt.parameters.options.multiple
import com.github.ajalt.clikt.parameters.options.option
import com.github.ajalt.clikt.parameters.options.split
import com.github.ajalt.clikt.parameters.types.file
import parsing.Parser

class App {
    private val files = mutableListOf<String>()

    fun run() {
        val parser = Parser()

        val modules = if (files.isNotEmpty())
            files.mapNotNull { file -> parser.parseFile(file) }
        else {
            listOf(parser.parse(System.`in`))
        }

        parser.printErrors()
        parser.clearErrors()
        println("Modules:")
        println(modules.joinToString(separator = "\n-----\n") { module -> module.readable() })
    }

    fun addFile(file: String) {
        files.add(file)
    }
}

class Compile: CliktCommand(help="compiles given sources") {
    override fun run() {
        TODO("Not yet implemented")
    }
}

class Parse: CliktCommand(help="parses given sources") {
    private val files by option("-f","--files").file(mustExist = true, mustBeReadable = true, canBeSymlink = false, canBeDir = false).multiple()

    override fun run() {
        val app = App()
        for (file in files)
            app.addFile(file.absolutePath)
        app.run()
    }
}

class Voidc : CliktCommand() {
    val verbose by option().flag("-v", "--verbose")
    override fun run() {
        //
    }
}

fun main(args: Array<String>) = Voidc().subcommands(Compile(), Parse()).main(args)