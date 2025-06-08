extension Optional {
    /// Unwraps the optional, throwing `ProtocolError` if it is `nil`.
    ///
    /// - Parameter error: The error to throw if the value is `nil`.
    /// - Returns: The unwrapped value.
    @inlinable
    func unwrap(or error: @autoclosure () -> ProtocolError) throws -> Wrapped {
        switch self {
        case .some(let wrapped):
            return wrapped
        case .none:
            throw error()
        }
    }
}
