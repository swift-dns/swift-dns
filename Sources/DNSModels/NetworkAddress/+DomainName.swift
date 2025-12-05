import SwiftIDNA

import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 10.15, *)
extension DomainName {
    package init(from buffer: inout DNSBuffer) throws {
        self.init()

        try self.read(from: &buffer)

        let checkResult = self.performCharacterCheck()

        switch checkResult {
        case .containsOnlyIDNANoOpCharacters:
            break
        case .onlyNeedsLowercasingOfUppercasedASCIILetters:
            /// Normalize to lowercase ASCII
            self._data.withUnsafeMutableReadableBytes { ptr in
                for idx in ptr.indices {
                    let byte = ptr[idx]
                    if byte.isUppercasedASCIILetter {
                        ptr[idx] = byte._uncheckedToLowercasedASCIILetterAssumingUppercasedLetter()
                    }
                }
            }
        case .mightChangeAfterIDNAConversion:
            /// Attempt to repair the domain name if it was not IDNA-compatible.
            /// This is technically not allowed in the DNS wire format, but we tolerate it.
            let description = self.utf8Representation()
            self = try Self.init(description)
        case .containsInvalidASCIIByte:
            throw ProtocolError.failedToValidate("DomainName", DNSBuffer(buffer: self._data))
        }
    }

    /// Reads the domain name from the buffer, appending it to the current domainName.
    package mutating func read(from buffer: inout DNSBuffer) throws {
        let startIndex = buffer.readerIndex

        var lastSuccessfulIdx = startIndex
        var idx = startIndex

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

                try flushIntoData(startIndex: startIndex, idx: idx, buffer: &buffer)

                return
            case let byte:
                switch byte & 0b1100_0000 {
                /// Pointer
                case 0b1100_0000:
                    let originalReaderIndex = buffer.readerIndex
                    /// The domainName processing is going to end after we're done with the pointer
                    try flushIntoData(startIndex: startIndex, idx: idx, buffer: &buffer)

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

    mutating func flushIntoData(
        startIndex: Int,
        idx: Int,
        buffer: inout DNSBuffer
    ) throws {
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

    private func utf8Representation() -> String {
        var domainName = self.map {
            String(buffer: $0)
        }.joined(separator: ".")
        if self.isFQDN {
            domainName.append(".")
        }
        return domainName
    }

    /// The result of checking characters for IDNA compliance.
    enum CharacterCheckResult {
        /// The sequence contains only characters that IDNA's toASCII function won't change.
        case containsOnlyIDNANoOpCharacters
        /// The sequence contains uppercased ASCII letters that will be lowercased after IDNA's toASCII conversion.
        /// The sequence does not contain any other characters that IDNA's toASCII function will change.
        case onlyNeedsLowercasingOfUppercasedASCIILetters
        /// The sequence contains characters that IDNA's toASCII function might or might not change.
        case mightChangeAfterIDNAConversion
        /// The sequence contains an invalid ASCII byte.
        /// Only characters allowed by `UInt8.isAcceptableDomainNameCharacter` are allowed.
        case containsInvalidASCIIByte
    }

    @available(swiftDNSApplePlatforms 10.15, *)
    func performCharacterCheck() -> CharacterCheckResult {
        var containsUppercased = false

        for label in self {
            let checkResult: CharacterCheckResult = label.withUnsafeReadableBytes { ptr in
                for idx in 0..<ptr.count {
                    let byte = ptr[idx]

                    /// Based on IDNA, all ASCII characters other than uppercased letters are 'valid'
                    /// Uppercased letters are each 'mapped' to their lowercased equivalent.
                    ///
                    /// Based on DNS wire format though, only latin letters, digits, and hyphens are allowed.
                    if byte.isUppercasedASCIILetter {
                        containsUppercased = true
                    } else if byte.isAcceptableDomainNameCharacter {
                        continue
                    } else if byte.isASCII {
                        return .containsInvalidASCIIByte
                    } else {
                        return .mightChangeAfterIDNAConversion
                    }
                }

                return containsUppercased
                    ? .onlyNeedsLowercasingOfUppercasedASCIILetters
                    : .containsOnlyIDNANoOpCharacters
            }

            switch checkResult {
            case .containsOnlyIDNANoOpCharacters,
                .onlyNeedsLowercasingOfUppercasedASCIILetters:
                continue
            case .mightChangeAfterIDNAConversion, .containsInvalidASCIIByte:
                return checkResult
            }
        }

        return containsUppercased
            ? .onlyNeedsLowercasingOfUppercasedASCIILetters
            : .containsOnlyIDNANoOpCharacters
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension DomainName {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeImmutableBuffer(self._data)
        buffer.writeInteger(UInt8(0))
    }
}
