public import DNSCore

import struct IPAddress.UnsignedInt128
public import struct NIOCore.ByteBuffer
public import struct NIOCore.ByteBufferView
public import enum NIOCore.Endianness

/// FIXME: investigating making this non-copyable
/// FXIME: CustomStringConvertible + Debug
@available(swiftDNSApplePlatforms 10.15, *)
@usableFromInline
package struct DNSBuffer: Sendable {
    @usableFromInline
    var _buffer: ByteBuffer
    /// Start index of the DNS portion of the packet the buffer
    /// This can be a negative number if e.g. this `DNSBuffer` is a slice of a parent `DNSBuffer`.
    ///
    /// FIXME: Maybe we shouldn't use this? we should be able to instead make sure the buffer always
    /// starts from the DNS portion of the packet?
    @usableFromInline
    let _dnsStartIndex: Int

    @usableFromInline
    package var readerIndex: Int {
        self._buffer.readerIndex
    }

    @usableFromInline
    package var writerIndex: Int {
        self._buffer.writerIndex
    }

    @usableFromInline
    package var readableBytes: Int {
        self._buffer.readableBytes
    }

    @usableFromInline
    package var readableBytesSpan: RawSpan {
        @_lifetime(borrow self)
        borrowing get {
            self._buffer.readableBytesSpan
        }
    }

    /// FIXME: don't expose ByteBufferView
    var readableBytesView: ByteBufferView {
        self._buffer.readableBytesView
    }

    package init(_buffer: ByteBuffer, _dnsStartIndex: Int) {
        self._buffer = _buffer
        self._dnsStartIndex = _dnsStartIndex
    }

    @inlinable
    package init() {
        self._buffer = ByteBuffer()
        self._dnsStartIndex = self._buffer.readerIndex
    }

    @inlinable
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

    package mutating func readUnsignedInt128() -> UnsignedInt128? {
        guard
            let high = self.readInteger(as: UInt64.self),
            let low = self.readInteger(as: UInt64.self)
        else {
            return nil
        }
        return UnsignedInt128(_low: low, _high: high)
    }

    @inlinable
    package mutating func readInteger<T: FixedWidthInteger>(as: T.Type = T.self) -> T? {
        self._buffer.readInteger(as: T.self)
    }

    package mutating func writeUnsignedInt128(_ value: UnsignedInt128) {
        self._buffer.writeInteger(value._high)
        self._buffer.writeInteger(value._low)
    }

    package mutating func writeInteger<T: FixedWidthInteger>(_ value: T) {
        self._buffer.writeInteger(value)
    }

    package func peekInteger<T: FixedWidthInteger>(as: T.Type = T.self) -> T? {
        self._buffer.peekInteger(as: T.self)
    }

    package mutating func peekBytes(length: Int) -> [UInt8]? {
        self._buffer.peekBytes(length: length)
    }

    package mutating func moveReaderIndex(forwardBy: Int) {
        self._buffer.moveReaderIndex(forwardBy: forwardBy)
    }

    @inlinable
    package mutating func moveReaderIndex(to offset: Int) {
        self._buffer.moveReaderIndex(to: offset)
    }

    /// Returns whether the move was possible and successful.
    package mutating func moveReaderIndex(toOffsetInDNSPortion offset: UInt16) -> Bool {
        /// We already know UInt16 < UInt32 so no need to check for that.
        guard offset >= 0, offset <= self.writerIndex else {
            return false
        }
        self._buffer.moveReaderIndex(to: self._dnsStartIndex + Int(offset))
        return true
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

    /// Truncates the buffer and returns the previous `writerIndex`.
    /// To limit the readable bytes to a specific length.
    /// Returns `nil` if the buffer has less readable bytes than requested.
    @inlinable
    mutating func truncate(length: Int) -> Int? {
        let readableBytes = self._buffer.readableBytes
        guard readableBytes >= length else {
            return nil
        }
        let writerIndex = self._buffer.writerIndex
        let limitedWriterIndex = writerIndex - (readableBytes - length)
        self._buffer.moveWriterIndex(to: limitedWriterIndex)
        return writerIndex
    }

    // FIXME: Use @inline(__always) ?
    /// Gives access to a version of the buffer that has a writerIndex limited to the requested length.
    /// Resets the writer index to the previous value after the body is executed.
    /// Does reset the writer index if the body throws an error.
    @inlinable
    package mutating func withTruncatedReadableBytes<T>(
        length: Int,
        orThrow error: ProtocolError,
        body: (inout DNSBuffer) throws -> T,
    ) throws -> T {
        guard let previousWriterIndex = self.truncate(length: length) else {
            throw error
        }
        do {
            let result = try body(&self)
            self._buffer.moveWriterIndex(to: previousWriterIndex)
            return result
        } catch {
            /// Do not move back the writer index if the body throws an error.
            /// The decoding logics will never try to restore from an error.
            /// The error will reach the DNSMessageDecoder and if we have moved back the writer index
            /// here, it will try to decode this again, although it would eventually break out since
            /// it'll try to re-read the whole Message and will try to read these bytes as a DNS
            /// header, which these are not, and so it'd fail again until the buffer is consumed.
            throw error
        }
    }

    /// Returns the remaining bytes in the buffer and moves the reader index.
    package mutating func readToEnd() -> ByteBuffer {
        defer {
            self._buffer.moveReaderIndex(forwardBy: self._buffer.readableBytes)
        }
        return self._buffer
    }

    /// Returns the remaining bytes in the buffer as a String and moves the reader index.
    package mutating func readToEndAsString() -> String {
        defer {
            self._buffer.moveReaderIndex(forwardBy: self._buffer.readableBytes)
        }
        return String(buffer: self._buffer)
    }

    /// Returns a copy of the remaining bytes in the buffer.
    package mutating func getToEnd() -> ByteBuffer {
        self._buffer
    }

    @inlinable
    package func getInteger<T: FixedWidthInteger>(
        at index: Int,
        endianness: Endianness = Endianness.big,
        as: T.Type = T.self
    ) -> T? {
        self._buffer.getInteger(at: index, as: T.self)
    }

    @discardableResult
    @inlinable
    package mutating func setInteger<T: FixedWidthInteger>(
        _ integer: T,
        at index: Int,
        endianness: Endianness = .big,
        as: T.Type = T.self
    ) -> Int {
        self._buffer.setInteger(
            integer,
            at: index,
            endianness: endianness,
            as: T.self
        )
    }

    @discardableResult
    @inlinable
    package mutating func writeImmutableBuffer(_ buffer: ByteBuffer) -> Int {
        self._buffer.writeImmutableBuffer(buffer)
    }

    @inlinable
    package func getSlice(at index: Int, length: Int) -> ByteBuffer? {
        self._buffer.getSlice(at: index, length: length)
    }

    package mutating func writeBuffer(_ buffer: ByteBuffer) {
        self._buffer.writeImmutableBuffer(buffer)
    }

    /// TODO: use ByteBuffer spans when available, so Span<UInt8>
    package mutating func writeBytes(_ bytes: some Collection<UInt8>) {
        self._buffer.writeBytes(bytes)
    }

    package mutating func writeBuffer(_ buffer: inout DNSBuffer) {
        self._buffer.writeBuffer(&buffer._buffer)
    }

    package mutating func readByteBuffer(length: Int) -> ByteBuffer? {
        self._buffer.readSlice(length: length)
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
    package mutating func readLengthPrefixedStringByteBuffer<IntegerType: FixedWidthInteger>(
        name: StaticString,
        decodeLengthAs _: IntegerType.Type = UInt8.self
    ) throws -> ByteBuffer {
        assert(
            IntegerType.max <= Int.max,
            /// ByteBuffer can't fit more than UInt32 bytes anyway.
            "This function assumes the length will fit into an Int."
        )
        guard let length = self.readInteger(as: IntegerType.self),
            let buffer = self._buffer.readSlice(length: Int(length))
        else {
            throw ProtocolError.failedToRead(name, self)
        }
        return buffer
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
        /// TODO: use ByteBuffer spans when available, so Span<UInt8>
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

    /// The length of the string MUST fit into the provided integer type.
    package mutating func writeLengthPrefixedString<IntegerType: FixedWidthInteger & Comparable>(
        name: StaticString,
        bytes: ByteBuffer,
        maxLength: IntegerType,
        fitLengthInto: IntegerType.Type
    ) throws {
        try self.writeLengthPrefixedString(
            name: name,
            bytes: bytes.readableBytesView,
            maxLength: maxLength,
            fitLengthInto: fitLengthInto
        )
    }

    @discardableResult
    @inlinable
    package mutating func writeLengthPrefixed<IntegerType: FixedWidthInteger>(
        endianness: Endianness = .big,
        as integer: IntegerType.Type,
        writeMessage: (inout ByteBuffer) throws -> Int
    ) throws -> Int {
        try self._buffer.writeLengthPrefixed(
            endianness: endianness,
            as: integer,
            writeMessage: writeMessage
        )
    }

    package mutating func withUnsafeReadableBytes<T>(
        _ body: (UnsafeRawBufferPointer) throws -> T
    ) rethrows -> T {
        try self._buffer.withUnsafeReadableBytes(body)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension DNSBuffer {
    @inlinable
    func rangeWithinReadableBytes(index: Int, length: Int) -> Range<Int>? {
        guard index >= self.readerIndex && length >= 0 else {
            return nil
        }

        // both these &--s are safe, they can't underflow because both left & right side are >= 0 (and index >= readerIndex)
        let indexFromReaderIndex = index &-- self.readerIndex
        assert(indexFromReaderIndex >= 0)
        guard indexFromReaderIndex <= self.readableBytes &-- length else {
            return nil
        }

        // safe, can't overflow, we checked it above.
        let upperBound = indexFromReaderIndex &++ length

        // uncheckedBounds is safe because `length` is >= 0, so the lower bound will always be lower/equal to upper
        return Range<Int>(uncheckedBounds: (lower: indexFromReaderIndex, upper: upperBound))
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension DNSBuffer: Equatable {
    @inlinable
    package static func == (lhs: DNSBuffer, rhs: DNSBuffer) -> Bool {
        lhs._buffer == rhs._buffer
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension DNSBuffer {
    package static func === (lhs: DNSBuffer, rhs: DNSBuffer) -> Bool {
        lhs._buffer == rhs._buffer
            && lhs._dnsStartIndex == rhs._dnsStartIndex
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension ByteBuffer {
    /// consuming doesn't do much here but that's what I expect (that the DNSBuffer is
    /// no longer touched after getting the underlying ByteBuffer)
    @inlinable
    package init(dnsBuffer: consuming DNSBuffer) {
        self = dnsBuffer._buffer
    }
}
