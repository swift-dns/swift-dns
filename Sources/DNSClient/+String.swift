extension String {
    @available(swiftDNSApplePlatforms 13, *)
    init(_uncheckedAssumingValidUTF8 span: Span<UInt8>) {
        self.init(unsafeUninitializedCapacity: span.count) { stringBuffer in
            let rawStringBuffer = UnsafeMutableRawBufferPointer(stringBuffer)
            span.withUnsafeBytes { spanPtr in
                rawStringBuffer.copyMemory(from: spanPtr)
            }
            return span.count
        }
    }
}
