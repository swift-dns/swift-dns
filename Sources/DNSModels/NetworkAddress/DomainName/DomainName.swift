import SwiftIDNA

public import struct NIOCore.ByteBuffer

/// A domain name.
///
/// [RFC 9499, DNS Terminology, March 2024](https://tools.ietf.org/html/rfc9499)
///
/// ```text
/// 2.1.6 Domain name
///
/// Any path of a directed acyclic graph can be represented by a domain name consisting of the labels of its nodes,
/// ordered by decreasing distance from the root(s) (whiscalaris the normal convention within the DNS).
/// ```
public struct DomainName: Sendable {
    /// Maximum allowed domain name length.
    @usableFromInline
    static var maxLength: UInt8 {
        255
    }

    /// Maximum allowed label length.
    @usableFromInline
    static var maxLabelLength: UInt8 {
        63
    }

    /// is Fully Qualified Domain DomainName.
    ///
    /// [RFC 9499, DNS Terminology, March 2024](https://tools.ietf.org/html/rfc9499)
    ///
    /// ```text
    /// 2.1.6 Domain name
    ///
    /// A domain name whose last label identifies a root of the graph is fully qualified other domain names whose
    /// labels form a strict prefix of a fully qualified domain name are relative to its first omitted node.
    /// ```
    public var isFQDN: Bool
    /// The raw data of the domain name, as in the wire format, excluding the root label (trailing null byte).
    /// Lowercased ASCII bytes only.
    ///
    /// Non-ASCII names are converted to ASCII based on the IDNA spec, in the initializers, and
    /// must/will never make it to the stored properties of `DomainName` such as `data`.
    /// Non-lowercased ASCII names are converted to lowercased ASCII in the initializers.
    /// Based on the DNS specs, all names are case-insensitive, and the bytes must be valid ASCII.
    /// This package goes further and normalizes every name to lowercase to avoid inconsistencies.
    ///
    /// [RFC 9499, DNS Terminology, March 2024](https://tools.ietf.org/html/rfc9499)
    ///
    /// ```text
    /// 2.1.12 Label
    ///
    /// An ordered list of zero or more octets that makes up a portion of a domain name.
    /// Using graph theory, a label identifies one node in a portion of the graph of all possible domain names.
    /// ```
    /// FIXME: investigate performance improvements, with something like `TinyVec`
    @usableFromInline
    package var data: ByteBuffer

    /// Returns the encoded length of this name, ignoring compression.
    ///
    /// The `isFQDN` flag is ignored, and the root label at the end is assumed to always be
    /// present, since it terminates the name in the DNS message format.
    var encodedLength: Int {
        self.data.readableBytes + 1
    }

    /// The number of labels in the name, excluding `*`.
    @inlinable
    public var labelsCount: Int {
        var containsWildcard = false
        var count = 0
        var iterator = self.makeIterator()
        while let (startIndex, length) = iterator.nextLabelPositionInNameData() {
            if count == 0,
                length == 1,
                self.data.getInteger(at: startIndex, as: UInt8.self) == UInt8.asciiStar
            {
                containsWildcard = true
            }
            count += 1
        }
        return containsWildcard ? (count - 1) : count
    }

    /// Whether the name is the DNS root name, aka `.`.
    @inlinable
    public var isRoot: Bool {
        self.isFQDN && self.data.readableBytes == 0
    }

    @usableFromInline
    package init(
        isFQDN: Bool = false,
        data: ByteBuffer = ByteBuffer()
    ) {
        self.isFQDN = isFQDN
        self.data = data

        /// Make sure the name is valid
        /// No empty labels
        assert(self.data.readableBytes <= Self.maxLength)
        assert(self.allSatisfy({ !($0.readableBytes == 0) }))
        assert(self.data.readableBytesView.allSatisfy(\.isASCII))
        assert(self.allSatisfy { $0.readableBytesView.allSatisfy { !$0.isUppercasedASCIILetter } })
    }
}

extension DomainName {
    @inlinable
    public static var root: Self {
        Self(isFQDN: true)
    }
}

extension DomainName: Hashable {
    /// Equality check without considering the FQDN flag.
    /// Users usually instantiate `DomainName` using a domain name which doesn't end in a dot.
    /// That mean user-instantiate `DomainName`s usually have `isFQDN` set to `false`.
    /// On the wire though, the root label is almost always present, so `isFQDN` is almost always `true`.
    /// So this method is useful to make sure a comparison of two `DomainName`s doesn't fail just because
    /// of the root-label indicator / FQN flag.
    public func isEssentiallyEqual(to other: Self) -> Bool {
        self.data == other.data
    }
}

extension DomainName: Sequence {
    public struct Iterator: Sendable, IteratorProtocol {
        public typealias Label = ByteBuffer

        /// TODO: will using Span help here? might skip some bounds checks or ref-count checks of ByteBuffer?
        let name: DomainName
        var startIndex: Int

        init(base: DomainName) {
            self.name = base
            self.startIndex = self.name.data.readerIndex
        }

        public mutating func nextLabelPositionInNameData() -> (startIndex: Int, length: Int)? {
            if self.startIndex == self.name.data.writerIndex {
                return nil
            }

            /// Such invalid data should never get to here so we consider this safe to force-unwrap
            let length = Int(
                self.name.data.getInteger(
                    at: self.startIndex,
                    as: UInt8.self
                )!
            )

            assert(
                length != 0,
                "Label length 0 means the root label has made it into name.data, which is not allowed"
            )

            defer {
                /// Move startIndex forward by the length, +1 for the length byte itself
                self.startIndex += length + 1
            }

            return (self.startIndex + 1, length)
        }

        public mutating func next() -> Label? {
            guard let (startIndex, length) = self.nextLabelPositionInNameData() else {
                return nil
            }

            /// Such invalid data should never get to here so we consider this safe to force-unwrap
            return self.name.data.getSlice(
                at: startIndex,
                length: length
            )!
        }
    }

    public func makeIterator() -> Self.Iterator {
        Iterator(base: self)
    }
}

extension DomainName {
    @usableFromInline
    enum ParsingState: Sendable, ~Copyable {
        case label
        case escape1
        case escape2(UInt8)
        case escape3(UInt8, UInt8)
    }

    @usableFromInline
    init(expectingASCIIBytes bytes: some BidirectionalCollection<UInt8>, name: StaticString) throws
    {
        guard bytes.allSatisfy(\.isASCII) else {
            /// FIXME: throw a better error
            throw ProtocolError.failedToValidate(name, DNSBuffer(bytes: bytes))
        }
        self.init()
        try Self.from(guaranteedASCIIBytes: bytes, into: &self)
    }

    @usableFromInline
    init(guaranteedASCIIBytes bytes: some BidirectionalCollection<UInt8>) throws {
        self.init()
        try Self.from(guaranteedASCIIBytes: bytes, into: &self)
    }

    @usableFromInline
    static func from(
        guaranteedASCIIBytes bytes: some BidirectionalCollection<UInt8>,
        into name: inout DomainName
    ) throws {
        assert(bytes.allSatisfy(\.isASCII))

        /// Reserve enough bytes for the wire format
        /// Assumes the
        let lengthWithoutRootLabel = bytes.last == 0 ? bytes.count - 1 : bytes.count

        if name.encodedLength + lengthWithoutRootLabel > Self.maxLength {
            throw ProtocolError.lengthLimitExceeded(
                "DomainName",
                actual: lengthWithoutRootLabel + 1,
                max: Int(Self.maxLength),
                DNSBuffer(bytes: bytes)
            )
        }

        name.data.reserveCapacity(lengthWithoutRootLabel)
        for label in bytes.split(separator: .asciiDot, omittingEmptySubsequences: false) {
            guard !label.isEmpty else {
                /// FIXME: throw a better error
                throw ProtocolError.failedToValidate("DomainName", DNSBuffer(bytes: bytes))
            }

            /// Outside the loop already checked the domain length is good, but still need to check label length
            if label.count > Self.maxLabelLength {
                throw ProtocolError.lengthLimitExceeded(
                    "DomainName.label",
                    actual: label.count,
                    max: Int(Self.maxLabelLength),
                    DNSBuffer(bytes: bytes)
                )
            }

            name.data.writeInteger(UInt8(label.count))
            name.data.writeBytes(label)
        }
    }
}

extension DomainName {
    package init(from buffer: inout DNSBuffer) throws {
        self.init()

        try self.read(from: &buffer)

        let checkResult = self.data.withUnsafeReadableBytes {
            IDNA.performCharacterCheck(dnsWireFormatBytes: $0)
        }
        switch checkResult {
        case .containsOnlyIDNANoOpCharacters:
            break
        case .onlyNeedsLowercasingOfUppercasedASCIILetters:
            /// Normalize to lowercase ASCII
            self.data.withUnsafeMutableReadableBytes { ptr in
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
            self = try Self.init(domainName: description)
        }
    }

    /// Reads the domain name from the buffer, appending it to the current name.
    package mutating func read(from buffer: inout DNSBuffer) throws {
        let startIndex = buffer.readerIndex

        var lastSuccessfulIdx = startIndex
        var idx = startIndex

        func flushIntoData() throws {
            if startIndex == idx {
                /// Root label
                buffer.moveReaderIndex(to: idx + 1)
            } else {
                let count = self.data.readableBytes
                let length = idx - startIndex
                if count == 0 {
                    self.data = buffer.getSlice(at: startIndex, length: length)!
                    buffer.moveReaderIndex(to: idx + 1)
                } else {
                    var slice = buffer.getSlice(at: startIndex, length: length)!
                    buffer.moveReaderIndex(to: idx + 1)
                    self.data.writeBuffer(&slice)
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

        /// FIXME: use _buffer
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
                    /// The name processing is going to end after we're done with the pointer
                    try flushIntoData()

                    buffer.moveReaderIndex(to: originalReaderIndex)

                    let pointer = try buffer.getInteger(at: idx, as: UInt16.self).unwrap(
                        or: .failedToRead("DomainName.label", buffer)
                    )
                    let offset = pointer & 0b0011_1111_1111_1111

                    /// TODO: use a cache of some sort to avoid re-parsing the same name multiple times
                    guard buffer.moveReaderIndex(toOffsetInDNSPortion: offset) else {
                        throw ProtocolError.failedToValidate("DomainName.label.offset", buffer)
                    }
                    try self.read(from: &buffer)
                    /// Reset the reader index to where we were, +2 for the pointer bytes
                    /// There is no null byte at the end, for pointers
                    buffer.moveReaderIndex(to: idx + 2)

                    // Pointer always finishes the name
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
        var name = self.map {
            String(buffer: $0)
        }.joined(separator: ".")
        if self.isFQDN {
            name.append(".")
        }
        return name
    }
}

extension DomainName {
    package func encode(into buffer: inout DNSBuffer, asCanonical: Bool = false) throws {
        buffer.writeImmutableBuffer(self.data)
        buffer.writeInteger(UInt8(0))
    }
}
