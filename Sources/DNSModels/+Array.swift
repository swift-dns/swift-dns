@available(swiftDNSApplePlatforms 10.15, *)
extension [UInt8] {
    #if canImport(Darwin)
    @usableFromInline
    #else
    @inlinable
    #endif
    borrowing func withSpan_Compatibility<T>(
        _ body: (Span<UInt8>) throws -> T
    ) rethrows -> T {
        #if canImport(Darwin)
        if #available(swiftDNSApplePlatforms 26, *) {
            return try body(self.span)
        }
        return try self.withUnsafeBufferPointer { bytesPtr in
            try body(bytesPtr.span)
        }
        #else
        return try body(self.span)
        #endif
    }
}
