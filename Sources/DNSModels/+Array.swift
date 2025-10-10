@available(swiftDNSApplePlatforms 13, *)
extension [UInt8] {
    @inline(__always)
    borrowing func withSpan_Compatibility<T>(
        _ body: (Span<UInt8>) throws -> T
    ) rethrows -> T {
        if #available(swiftDNSApplePlatforms 26, *) {
            return try body(self.span)
        }
        return try self.withUnsafeBufferPointer { bytesPtr in
            try body(bytesPtr.span)
        }
    }
}
