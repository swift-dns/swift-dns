extension String {
    @available(swiftDNSApplePlatforms 10.15, *)
    init(_uncheckedAssumingValidUTF8 span: Span<UInt8>) {
        self.init(unsafeUninitializedCapacity_Compatibility: span.count) { stringBuffer in
            let rawStringBuffer = UnsafeMutableRawBufferPointer(stringBuffer)
            span.withUnsafeBytes { spanPtr in
                rawStringBuffer.copyMemory(from: spanPtr)
            }
            return span.count
        }
    }

    #if canImport(Darwin)
    @usableFromInline
    init(
        unsafeUninitializedCapacity_Compatibility capacity: Int,
        initializingUTF8With initializer: (
            _ buffer: UnsafeMutableBufferPointer<UInt8>
        ) throws -> Int
    ) rethrows {
        if #available(swiftDNSApplePlatforms 11, *) {
            try self.init(unsafeUninitializedCapacity: capacity) { buffer in
                try initializer(buffer)
            }
        } else {
            let array = try [UInt8].init(
                unsafeUninitializedCapacity: capacity
            ) { buffer, initializedCount in
                initializedCount = try initializer(buffer)
            }
            self.init(decoding: array, as: UTF8.self)
        }
    }
    #else
    /// @_transparent helps mitigate some performance regressions on Linux that happened when
    /// moving from directly using the underlying initializer, to this compatibility initializer.
    @_transparent
    @inlinable
    init(
        unsafeUninitializedCapacity_Compatibility capacity: Int,
        initializingWith initializer: (
            _ buffer: UnsafeMutableBufferPointer<UInt8>
        ) throws -> Int
    ) rethrows {
        try self.init(unsafeUninitializedCapacity: capacity) { buffer in
            try initializer(buffer)
        }
    }
    #endif
}
