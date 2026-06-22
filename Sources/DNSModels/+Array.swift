@available(SwiftStdlib 5.1, *)
extension [UInt8] {
    @inline(__always)
    borrowing func withSpan_Compatibility<T>(
        _ body: (Span<UInt8>) throws -> T
    ) rethrows -> T {
        if #available(SwiftStdlib 6.2, *) {
            return try body(self.span)
        }
        return try self.withUnsafeBufferPointer { bytesPtr in
            try body(bytesPtr.span)
        }
    }
}
