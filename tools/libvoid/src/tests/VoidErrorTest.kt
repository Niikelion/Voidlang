import org.junit.jupiter.api.Test

internal class VoidErrorTest {
    @Test
    fun checkGetters() {
        val err = VoidError(6, 11, "source")
        assert(err.line == 6)
        assert(err.pos == 11)
        assert(err.source == "source")
    }
}