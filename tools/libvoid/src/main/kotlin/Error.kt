open class VoidError(
    val line: Int,
    val pos: Int,
    dataSource: String? = null
) {
    val source: String = dataSource ?: "input"
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