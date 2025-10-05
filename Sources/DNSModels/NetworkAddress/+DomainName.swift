import SwiftIDNA

import struct NIOCore.ByteBuffer

extension DomainName {
    package init(from buffer: inout DNSBuffer) throws {
        self.init()

        try self.read(from: &buffer)

        let checkResult = self._data.withUnsafeReadableBytes {
            IDNA.performCharacterCheck(dnsWireFormatBytes: $0)
        }
        switch checkResult {
        case .containsOnlyIDNANoOpCharacters:
            break
        case .onlyNeedsLowercasingOfUppercasedASCIILetters:
            /// Normalize to lowercase ASCII
            self._data.withUnsafeMutableReadableBytes { ptr in
                for idx in ptr.indices {
                    let byte = ptr[idx]
                    if byte.isUppercasedASCIILetter {
                        ptr[idx] = byte.uncheckedToLowercasedASCIILetter()
                    }
                }
            }
        case .mightChangeAfterIDNAConversion:
            /// Attempt to repair the domain name if it was not IDNA-compatible.
            /// This is technically not allowed in the DNS wire format, but we tolerate it.
            let description = self.utf8Representation()
            self = try Self.init(string: description)
        }
    }

    /// Reads the domain name from the buffer, appending it to the current domainName.
    package mutating func read(from buffer: inout DNSBuffer) throws {
        let startIndex = buffer.readerIndex

        var lastSuccessfulIdx = startIndex
        var idx = startIndex

        func flushIntoData() throws {
            if startIndex == idx {
                /// Root label
                buffer.moveReaderIndex(to: idx + 1)
            } else {
                let count = self._data.readableBytes
                let length = idx - startIndex
                if count == 0 {
                    self._data = buffer.getSlice(at: startIndex, length: length)!
                    buffer.moveReaderIndex(to: idx + 1)
                } else {
                    var slice = buffer.getSlice(at: startIndex, length: length)!
                    buffer.moveReaderIndex(to: idx + 1)
                    self._data.writeBuffer(&slice)
                }

                if self.encodedLength > Self.maxLength {
                    throw ProtocolError.lengthLimitExceeded(
                        "DomainName.label",
                        actual: self.encodedLength,
                        max: Int(Self.maxLength),
                        buffer
                    )
                }
            }
        }

        while let byte = buffer.getInteger(at: idx, as: UInt8.self) {
            lastSuccessfulIdx = idx
            switch byte {
            case 0:
                // RFC 1035 Section 3.1 - DomainName space definitions
                //
                // Domain names in messages are expressed in terms of a sequence of labels.
                // Each label is represented as a one octet length field followed by that
                // number of octets.  **Since every domain name ends with the null label of
                // the root, a domain name is terminated by a length byte of zero.**  The
                // high order two bits of every length octet must be zero, and the
                // remaining six bits of the length field limit the label to 63 octets or
                // less.
                self.isFQDN = true

                try flushIntoData()

                return
            case let byte:
                switch byte & 0b1100_0000 {
                /// Pointer
                case 0b1100_0000:
                    let originalReaderIndex = buffer.readerIndex
                    /// The domainName processing is going to end after we're done with the pointer
                    try flushIntoData()

                    buffer.moveReaderIndex(to: originalReaderIndex)

                    let pointer = try buffer.getInteger(at: idx, as: UInt16.self).unwrap(
                        or: .failedToRead("DomainName.label", buffer)
                    )
                    let offset = pointer & 0b0011_1111_1111_1111

                    /// TODO: use a cache of some sort to avoid re-parsing the same domainName multiple times
                    guard buffer.moveReaderIndex(toOffsetInDNSPortion: offset) else {
                        throw ProtocolError.failedToValidate("DomainName.label.offset", buffer)
                    }
                    try self.read(from: &buffer)
                    /// Reset the reader index to where we were, +2 for the pointer bytes
                    /// There is no null byte at the end, for pointers
                    buffer.moveReaderIndex(to: idx + 2)

                    // Pointer always finishes the domainName
                    return
                /// Normal character-string length
                case 0b0000_0000:
                    /// At this point, `byte` is the character-string length indicator
                    /// The length is also guaranteed to be <= 63 since the first 2 bytes are off
                    /// +1 for the length byte itself
                    idx += Int(byte) + 1
                default:
                    throw ProtocolError.badCharacter(
                        in: "DomainName.label",
                        character: byte,
                        buffer
                    )
                }
            }
        }

        /// Should finish with a null byte, so this is an error
        /// Move the reader index so maybe next decodings don't get stuck on this
        buffer.moveReaderIndex(to: lastSuccessfulIdx)
        throw ProtocolError.failedToValidate("DomainName", buffer)
    }

    private func utf8Representation() -> String {
        var domainName = self.map {
            String(buffer: $0)
        }.joined(separator: ".")
        if self.isFQDN {
            domainName.append(".")
        }
        return domainName
    }
}

extension DomainName {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeImmutableBuffer(self._data)
        buffer.writeInteger(UInt8(0))
    }
}
