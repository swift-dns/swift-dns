extension String {
    package var lengthInDNSWireProtocol: Int {
        self.utf8.count + 1  // +1 for the length byte
    }

    @available(swiftDNSApplePlatforms 13, *)
    @inline(__always)
    mutating func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        if #available(swiftDNSApplePlatforms 26, *) {
            return try body(self.utf8Span.span)
        }
        do {
            return try self.withUTF8 { buffer in
                try body(buffer.span)
            }
        } catch let error as E {
            throw error
        } catch {
            fatalError("Unexpected error: \(String(reflecting: error))")
        }
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension Substring {
    @inline(__always)
    mutating func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        if #available(swiftDNSApplePlatforms 26, *) {
            return try body(self.utf8Span.span)
        }
        do {
            return try self.withUTF8 { buffer in
                try body(buffer.span)
            }
        } catch let error as E {
            throw error
        } catch {
            fatalError("Unexpected error: \(String(reflecting: error))")
        }
    }
}
