package parsing

import org.junit.jupiter.api.Test

internal class ParserTest {
    @Test
    fun parseSimpleProgram() {
        val parser = Parser()
        val module = parser.parse(
                "module simple\n" +
                "\n" +
                "import stl\n" +
                "\n" +
                "int main() {\n" +
                "   float x = 5\n" +
                "   return x\n" +
                "}\n")
        assert(parser.getErrors().isEmpty())
        assert(module.name == "simple")
    }
}