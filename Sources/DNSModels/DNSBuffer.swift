public import struct NIOCore.ByteBuffer
public import struct NIOCore.ByteBufferView
public import enum NIOCore.Endianness

/// FIXME: investigating making this non-copyable
/// FXIME: CustomStringConvertible + Debug
/// use ~Copyable?
@usableFromInline
package struct DNSBuffer: Sendable {
    @usableFromInline
    var _buffer: ByteBuffer
    /// Start index of the DNS portion of the packet the buffer
    ///
    /// TODO: Maybe we shouldn't use this? we should be able to instead make sure the buffer always
    /// Start from the DNS portion of the packet?
    @usableFromInline
    let _dnsStartIndex: Int

    var readerIndex: Int {
        self._buffer.readerIndex
    }

    var writerIndex: Int {
        self._buffer.writerIndex
    }

    var readableBytes: Int {
        self._buffer.readableBytes
    }

    /// FIXME: don't expose ByteBufferView
    var readableBytesView: ByteBufferView {
        self._buffer.readableBytesView
    }

    package init(_buffer: ByteBuffer, _dnsStartIndex: Int) {
        self._buffer = _buffer
        self._dnsStartIndex = _dnsStartIndex
    }

    package init() {
        self._buffer = ByteBuffer()
        self._dnsStartIndex = self._buffer.readerIndex
    }

    package init(buffer: ByteBuffer) {
        self._buffer = buffer
        self._dnsStartIndex = self._buffer.readerIndex
    }

    package init(string: String) {
        self._buffer = ByteBuffer(string: string)
        self._dnsStartIndex = self._buffer.readerIndex
    }

    package init(integer: some FixedWidthInteger) {
        self._buffer = ByteBuffer(integer: integer)
        self._dnsStartIndex = self._buffer.readerIndex
    }

    package init(bytes: some Sequence<UInt8>) {
        self._buffer = ByteBuffer(bytes: bytes)
        self._dnsStartIndex = self._buffer.readerIndex
    }

    package mutating func reserveCapacity(minimumWritableBytes: Int) {
        self._buffer.reserveCapacity(minimumWritableBytes: minimumWritableBytes)
    }

    package mutating func readInteger<T: FixedWidthInteger>(as: T.Type = T.self) -> T? {
        self._buffer.readInteger(as: T.self)
    }

    package mutating func writeInteger<T: FixedWidthInteger>(_ value: T) {
        self._buffer.writeInteger(value)
    }

    package mutating func writeString(_ string: String) {
        self._buffer.writeString(string)
    }

    package mutating func peekInteger<T: FixedWidthInteger>(as: T.Type = T.self) -> T? {
        self._buffer.peekInteger(as: T.self)
    }

    package mutating func peekBytes(length: Int) -> [UInt8]? {
        self._buffer.peekBytes(length: length)
    }

    package mutating func moveReaderIndex(forwardBy: Int) {
        self._buffer.moveReaderIndex(forwardBy: forwardBy)
    }

    package mutating func moveReaderIndex(to offset: Int) {
        self._buffer.moveReaderIndex(to: offset)
    }

    package mutating func moveReaderIndex(toOffsetInDNSPortion offset: Int) {
        self._buffer.moveReaderIndex(to: self._dnsStartIndex + offset)
    }

    package mutating func moveDNSPortionStartIndex(forwardBy offset: Int) {
        self = DNSBuffer(
            _buffer: self._buffer,
            _dnsStartIndex: self._dnsStartIndex + offset
        )
    }

    package mutating func readString(length: Int) -> String? {
        self._buffer.readString(length: length)
    }

    package mutating func readInlineArray<
        let count: Int,
        IntegerType: FixedWidthInteger
    >(
        endianness: Endianness = .big,
        as: InlineArray<count, IntegerType>.Type = InlineArray<count, IntegerType>.self
    ) -> InlineArray<count, IntegerType>? {
        let length = MemoryLayout<IntegerType>.size
        let bytesRequired = length &* count

        guard self.readableBytes >= bytesRequired else {
            return nil
        }

        return self._buffer.readWithUnsafeReadableBytes {
            ptr -> (Int, InlineArray<count, IntegerType>) in
            assert(ptr.count >= bytesRequired)
            let values: InlineArray<count, IntegerType> = InlineArray { index in
                switch endianness {
                case .big:
                    return IntegerType(
                        bigEndian: ptr.load(
                            fromByteOffset: index &* length,
                            as: IntegerType.self
                        )
                    )
                case .little:
                    return IntegerType(
                        littleEndian: ptr.load(
                            fromByteOffset: index &* length,
                            as: IntegerType.self
                        )
                    )
                }
            }
            return (bytesRequired, values)
        }
    }

    package mutating func readSlice(length: Int) -> DNSBuffer? {
        self._buffer.readSlice(length: length).map {
            DNSBuffer(_buffer: $0, _dnsStartIndex: self._dnsStartIndex)
        }
    }

    /// Returns the remaining bytes in the buffer and moves the reader index.
    package mutating func readToEnd() -> [UInt8] {
        defer {
            self._buffer.moveReaderIndex(forwardBy: self._buffer.readableBytes)
        }
        return [UInt8](buffer: self._buffer)
    }

    /// Returns the remaining bytes in the buffer as a String and moves the reader index.
    package mutating func readToEndAsString() -> String {
        defer {
            self._buffer.moveReaderIndex(forwardBy: self._buffer.readableBytes)
        }
        return String(buffer: self._buffer)
    }

    /// Returns a copy of the remaining bytes in the buffer.
    package mutating func getToEnd() -> [UInt8] {
        [UInt8](buffer: self._buffer)
    }

    package mutating func writeBytes<let elementCount: Int>(
        _ bytes: InlineArray<elementCount, UInt8>
    ) {
        /// TODO: optimize. Currently `InlineArray -> UnsafePointer` conversion is broken in the compiler.
        var accumulatedBytes: [UInt8] = []
        accumulatedBytes.reserveCapacity(bytes.count)
        for idx in bytes.indices {
            accumulatedBytes.append(bytes[idx])
        }
        self.writeBytes(accumulatedBytes)
    }

    package mutating func writeBytes(_ bytes: some Sequence<UInt8>) {
        self._buffer.writeBytes(bytes)
    }

    package mutating func writeBuffer(_ buffer: inout DNSBuffer) {
        self._buffer.writeBuffer(&buffer._buffer)
    }

    package mutating func readBytes(length: Int) -> [UInt8]? {
        self._buffer.readBytes(length: length)
    }

    /// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035#section-3.3)
    ///
    /// ```text
    /// <character-string> is a single
    /// length octet followed by that number of characters.  <character-string>
    /// is treated as binary information, and can be up to 256 characters in
    /// length (including the length octet).
    /// ```
    /// The spec's <character-string> is a specialized version of this function where `LengthType == UInt8`.
    package mutating func readLengthPrefixedString<IntegerType: FixedWidthInteger>(
        name: StaticString,
        decodeLengthAs _: IntegerType.Type = UInt8.self
    ) throws -> [UInt8] {
        assert(
            IntegerType.max <= Int.max,
            /// ByteBuffer can't fit more than UInt32 bytes anyway.
            "This function assumes the length will fit into an Int."
        )
        guard let length = self.readInteger(as: IntegerType.self),
            let bytes = self.readBytes(length: Int(length))
        else {
            throw ProtocolError.failedToRead(name, self)
        }
        return bytes
    }

    /// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035#section-3.3)
    ///
    /// ```text
    /// <character-string> is a single
    /// length octet followed by that number of characters.  <character-string>
    /// is treated as binary information, and can be up to 256 characters in
    /// length (including the length octet).
    /// ```
    package mutating func readLengthPrefixedStringAsString(name: StaticString) throws -> String {
        guard let length = self.readInteger(as: UInt8.self),
            let string = self.readString(
                length: Int(length)/// `UInt8` -> `Int` is safe
            )
        else {
            throw ProtocolError.failedToRead(name, self)
        }
        return string
    }

    /// The length of the string MUST fit into the provided integer type.
    package mutating func writeLengthPrefixedString<IntegerType: FixedWidthInteger & Comparable>(
        name: StaticString,
        bytes: some Collection<UInt8>,
        maxLength: IntegerType,
        fitLengthInto: IntegerType.Type
    ) throws {
        assert(
            IntegerType.max <= Int.max,
            /// ByteBuffer can't fit more than UInt32 bytes anyway.
            "This function assumes the length will fit into an Int."
        )
        /// The `IntegerType(truncatingIfNeeded:)` initializer below relies on this check
        if bytes.count > maxLength {
            throw ProtocolError.lengthLimitExceeded(
                name,
                actual: bytes.count,
                max: Int(maxLength),
                self
            )
        }
        /// At this point we can assume that the IntegerType can fit the byte count already since
        /// maxLength was checked before.
        let length = IntegerType(truncatingIfNeeded: bytes.count)
        self.writeInteger(length)
        self.writeBytes(bytes)
    }
}

extension DNSBuffer: Equatable {
    @inlinable
    package static func == (lhs: DNSBuffer, rhs: DNSBuffer) -> Bool {
        lhs._buffer == rhs._buffer
    }
}
extension DNSBuffer {
    package static func === (lhs: DNSBuffer, rhs: DNSBuffer) -> Bool {
        lhs._buffer == rhs._buffer
            && lhs._dnsStartIndex == rhs._dnsStartIndex
    }
}

extension ByteBuffer {
    package init(dnsBuffer: DNSBuffer) {
        self = dnsBuffer._buffer
    }
}
