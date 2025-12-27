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
    #else
    @inlinable
    #endif
    init(
        unsafeUninitializedCapacity_Compatibility capacity: Int,
        initializingUTF8With initializer: (
            _ buffer: UnsafeMutableBufferPointer<UInt8>
        ) throws -> Int
    ) rethrows {
        #if canImport(Darwin)
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
        #else
        try self.init(unsafeUninitializedCapacity: capacity) { buffer in
            try initializer(buffer)
        }
        #endif
    }
}
