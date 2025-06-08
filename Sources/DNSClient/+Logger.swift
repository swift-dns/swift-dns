public import Logging

extension Logger {
    @inlinable
    static var noopLogger: Logger {
        Logger(label: "", factory: SwiftLogNoOpLogHandler.init)
    }
}
