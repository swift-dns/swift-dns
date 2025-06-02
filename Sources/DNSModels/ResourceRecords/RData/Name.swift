package import struct NIOCore.ByteBuffer
package import struct NIOCore.ByteBufferView

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
public struct Name: Sendable {
    /// Maximum allowed domain name length.
    public static var maxLength: UInt8 {
        255
    }

    /// Maximum allowed label length.
    public static var maxLabelLength: UInt8 {
        63
    }

    /// is Fully Qualified Domain Name.
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
    /// FIXME: investigate performance improvements, with something like `ArraySlice<UInt8>` or `TinyVec`
    /// The data of each label in the name.
    ///
    /// [RFC 9499, DNS Terminology, March 2024](https://tools.ietf.org/html/rfc9499)
    ///
    /// ```text
    /// 2.1.12 Label
    ///
    /// An ordered list of zero or more octets that makes up a portion of a domain name.
    /// Using graph theory, a label identifies one node in a portion of the graph of all possible domain names.
    /// ```
    public var data: [UInt8]
    /// The end of each label in the `data` array.
    public var borders: [UInt8]

    /// Returns the encoded length of this name, ignoring compression.
    ///
    /// The `isFQDN` flag is ignored, and the root label at the end is assumed to always be
    /// present, since it terminates the name in the DNS message format.
    var encodedLength: Int {
        self.borders.count + self.data.count + 1
    }

    /// The number of labels in the name, excluding `*`.
    public var labelsCount: Int {
        let count = self.borders.count
        return (self.data.first == UInt8.asciiStar) ? count - 1 : count
    }

    /// Whether the name is the DNS root name, aka `.`.
    public var isRoot: Bool {
        self.isFQDN && self.borders.isEmpty
    }

    public init(
        isFQDN: Bool = false,
        data: [UInt8] = [],
        borders: [UInt8] = []
    ) {
        self.isFQDN = isFQDN
        self.data = data
        self.borders = borders
    }
}

extension Name {
    @inlinable
    public static var root: Self {
        Self(isFQDN: true, data: [], borders: [])
    }
}

extension Name: Sequence {
    public struct Iterator: IteratorProtocol {
        public typealias Label = [UInt8]

        let name: Name
        var start: Int
        let end: Int

        public mutating func next() -> Label? {
            if self.start >= self.end {
                return nil
            }

            guard self.name.borders.count > self.start else {
                return nil
            }

            let end = self.name.borders[self.start]
            let start: UInt8 =
                switch self.start {
                case 0: 0
                default: self.name.borders[self.start - 1]
                }
            self.start += 1

            var bytes: [UInt8] = []
            bytes.reserveCapacity(Int(end - start))
            for idx in start..<end {
                bytes.append(self.name.data[Int(idx)])
            }

            return bytes
        }
    }

    public func makeIterator() -> Self.Iterator {
        Iterator(
            name: self,
            start: 0,
            end: self.borders.count,
        )
    }
}

extension Name {
    enum ParsingState {
        case label
        case escape1
        case escape2(UInt8)
        case escape3(UInt8, UInt8)
    }

    public init(string: some StringProtocol, origin: Self? = nil) throws {
        try self.init(bytes: string.utf8, origin: origin)
    }

    public init(bytes: some Collection<UInt8>, origin: Self? = nil) throws {
        self.init()
        // short circuit root parse
        if bytes.count == 1, bytes.first == UInt8.asciiDot {
            self.isFQDN = true
            return
        }

        var label = [UInt8]()

        var state = ParsingState.label

        for char in bytes {
            switch state {
            case .label:
                switch char {
                case UInt8.asciiDot:
                    try self.extendName(label)
                    label.removeAll(keepingCapacity: true)
                case UInt8.asciiBackslash:
                    state = .escape1
                case let char
                where !(Unicode.Scalar(char).properties.generalCategory == .control)
                    && !Unicode.Scalar(char).properties.isWhitespace:
                    label.append(char)
                default:
                    throw ProtocolError.badCharacter(
                        in: "Name.bytes",
                        character: char,
                        ByteBuffer(bytes: bytes)
                    )
                }
            case .escape1:
                if Unicode.Scalar(char).properties.generalCategory.isNumeric {
                    state = .escape2(char)
                } else {
                    /// it's a single escaped char
                    label.append(char)
                    state = .label
                }
            case .escape2(let i):
                if Unicode.Scalar(char).properties.generalCategory.isNumeric {
                    state = .escape3(i, char)
                } else {
                    throw ProtocolError.badCharacter(
                        in: "Name.bytes",
                        character: char,
                        ByteBuffer(bytes: bytes)
                    )
                }
            case .escape3(let i, let ii):
                guard Unicode.Scalar(char).properties.generalCategory.isNumeric else {
                    throw ProtocolError.badCharacter(
                        in: "Name.bytes",
                        character: char,
                        ByteBuffer(bytes: bytes)
                    )
                }
                /// octal conversion
                let val: UInt32 =
                    (UInt32(i) * 8 * 8)
                    + (UInt32(ii) * 8)
                    + UInt32(char)
                guard let new = Unicode.Scalar(val) else {
                    throw ProtocolError.badCharacter(
                        in: "Name.bytes",
                        character: char,
                        ByteBuffer(bytes: bytes)
                    )
                }
                label.append(contentsOf: new.utf8)
                state = .label
            }
        }

        if !label.isEmpty {
            try self.extendName(label)
        }

        // Check if the last character processed was an unescaped `.`
        if label.isEmpty && !bytes.isEmpty {
            self.isFQDN = true
        } else if let other = origin {
            try self.appendDomain(other)
        }
    }

    mutating func appendDomain(_ domain: Self) throws {
        try self.appendName(domain)
        self.isFQDN = true
    }

    mutating func appendName(_ name: Self) throws {
        for label in name {
            try self.extendName(label)
        }
        self.isFQDN = name.isFQDN
    }

    /// Extend the name with the offered label, and ensure maximum name length is not exceeded.
    mutating func extendName(_ label: [UInt8]) throws {
        let newLength = self.encodedLength + label.count + 1

        if newLength > Self.maxLength {
            throw ProtocolError.lengthLimitExceeded(
                "Name.label",
                actual: newLength,
                max: Int(Self.maxLength),
                ByteBuffer(bytes: label)
            )
        }

        self.data.append(contentsOf: label)
        /// Safe to force unwrap because data is `InlineArray<32, UInt8>` aka 32 bytes max
        self.borders.append(UInt8(exactly: self.data.count)!)
    }
}

extension Name {
    /// [RFC 1035, Domain Names - Implementation and Specification, November 1987](https://datatracker.ietf.org/doc/html/rfc1035#section-3.1)
    package init(from buffer: inout ByteBuffer) throws {
        self.init()

        guard let endIndex = buffer.readableBytesView.firstIndex(of: 0) else {
            throw ProtocolError.failedToRead("Name.label", buffer)
        }
        /// Guranteed to be at least 1 byte (the null byte)
        let byteCount = endIndex - buffer.readerIndex + 1
        var domainBuffer = buffer.readSlice(length: byteCount).unsafelyUnwrapped  // safe

        var nameBytes = ByteBuffer()

        var notFirst = false
        /// TODO: Optimize no copying bytes around
        while let labelLength = domainBuffer.readInteger(as: UInt8.self) {
            if labelLength == .nullByte {
                /// End of name
                break
            }
            /// TODO: optimize no need to write dots manually. Shouldn't need to write static data
            if notFirst {
                nameBytes.writeInteger(UInt8.asciiDot)
            } else {
                notFirst = true
            }
            guard var slice = domainBuffer.readSlice(length: Int(labelLength)) else {
                throw ProtocolError.failedToRead("Name.label", buffer)
            }
            nameBytes.writeBuffer(&slice)
        }

        try self.init(bytes: nameBytes.readableBytesView)
    }
}

extension Name {
    package func asString() -> String {
        var scalars: [UnicodeScalar] = []
        scalars.reserveCapacity(self.encodedLength)

        var iterator = self.makeIterator()
        if let first = iterator.next() {
            scalars.append(contentsOf: first.map(UnicodeScalar.init))
        }

        while let label = iterator.next() {
            scalars.append(".")
            scalars.append(contentsOf: label.map(UnicodeScalar.init))
        }

        if self.isFQDN {
            scalars.append(".")
        }
        return String(String.UnicodeScalarView(scalars))
    }
}

extension Name {
    package func encode(into buffer: inout ByteBuffer, asCanonical: Bool = false) throws {
        let startingReadableBytes = buffer.readableBytes  // lazily assert the size is less than 256...

        for label in self {
            try buffer.writeCharacterString(
                name: "Name.labels[]",
                bytes: label,
                maxLength: Self.maxLabelLength,
                fitLengthInto: UInt8.self
            )
        }

        /// Write end
        buffer.writeInteger(0 as UInt8)

        let length = buffer.readableBytes - startingReadableBytes
        if length > Self.maxLength {
            throw ProtocolError.lengthLimitExceeded(
                "Name",
                actual: length,
                max: Int(Self.maxLength),
                buffer
            )
        }
    }
}
