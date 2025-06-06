package import struct NIOCore.ByteBuffer
package import enum NIOCore.Endianness

extension ByteBuffer {
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

        return self.readWithUnsafeReadableBytes {
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
            let string = self.readString(length: Int(length))
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
        if bytes.count > maxLength {
            throw ProtocolError.lengthLimitExceeded(
                name,
                actual: bytes.count,
                max: Int(maxLength),
                self
            )
        }
        /// TODO: is this the optimal conversion?
        /// At this point we can assume that the IntegerType can fit the byte count already since
        /// maxLength was checked before?
        let length = IntegerType(bytes.count)
        self.writeInteger(length)
        self.writeBytes(bytes)
    }
}
