open class VoidError(
    line: Int,
    pos: Int,
    source: String? = null
): Positional(line, pos, source) {
    override fun toString(): String {
        return "$source($line:$pos): " + getErrorMsg()
    }

    protected open fun getErrorMsg(): String {
        return ""
    }
}

class IOError(file: String, private val msg: String): VoidError(0, 0, file) {
    override fun getErrorMsg(): String {
        return "io error - $msg"
    }
}