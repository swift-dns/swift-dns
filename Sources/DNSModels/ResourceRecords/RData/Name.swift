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
    @usableFromInline
    static var maxLength: UInt8 {
        255
    }

    /// Maximum allowed label length.
    @usableFromInline
    static var maxLabelLength: UInt8 {
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
    @usableFromInline
    package var isFQDN: Bool
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
    @usableFromInline
    package var data: [UInt8]
    /// The end of each label in the `data` array.
    @usableFromInline
    package var borders: [UInt8]

    /// Returns the encoded length of this name, ignoring compression.
    ///
    /// The `isFQDN` flag is ignored, and the root label at the end is assumed to always be
    /// present, since it terminates the name in the DNS message format.
    var encodedLength: Int {
        self.borders.count + self.data.count + 1
    }

    /// The number of labels in the name, excluding `*`.
    @inlinable
    public var labelsCount: Int {
        let count = self.borders.count
        return (self.data.first == UInt8.asciiStar) ? (count - 1) : count
    }

    /// Whether the name is the DNS root name, aka `.`.
    @inlinable
    public var isRoot: Bool {
        self.isFQDN && self.borders.isEmpty
    }

    @usableFromInline
    package init(
        isFQDN: Bool = false,
        data: [UInt8] = [],
        borders: [UInt8] = []
    ) {
        self.isFQDN = isFQDN
        self.data = data
        self.borders = borders
        /// No empty labels
        assert(self.allSatisfy({ !$0.isEmpty }))
    }
}

extension Name {
    @inlinable
    public static var root: Self {
        Self(isFQDN: true, data: [], borders: [])
    }
}

extension Name: Equatable {
    /// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
    ///
    /// ```text
    /// For all parts of the DNS that are part of the official protocol, all
    /// comparisons between character strings (e.g., labels, domain names, etc.)
    /// are done in a case-insensitive manner.
    /// ```
    ///
    /// Does a **case-insensitive** equality check of 2 domain names.
    /// Not constant time if that matters to your usecase.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isFQDN == rhs.isFQDN
            && lhs.borders == rhs.borders
            && caseInsensitiveEquals(lhs.data, rhs.data)
    }

    /// TODO: check compatibility with RFC 3490 "Internationalizing Domain Names in Applications (IDNA)"
    @usableFromInline
    static func caseInsensitiveEquals(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
        /// Short circuit if the bytes are the same
        if lhs == rhs {
            return true
        }

        /// Slower path: Compare case-insensitively assuming ASCII.
        /// Names are validated or converted to ASCII at initialization time.
        guard lhs.count == rhs.count else {
            return false
        }

        for (l, r) in zip(lhs, rhs) {
            /// https://ss64.com/ascii.html
            /// The difference between an upper and lower cased ASCII byte is their sixth bit.
            guard (l & 0b1101_1111) == (r & 0b1101_1111) else {
                return false
            }
        }

        return true
    }
}

extension Name: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.isFQDN)
        hasher.combine(self.borders)
        hasher.combine(self.data)
    }
}

extension Name: Sequence {
    public struct Iterator: IteratorProtocol {
        public typealias Label = [UInt8]

        let name: Name
        var start: Int
        let end: Int

        public init(base: Name) {
            self.name = base
            self.start = 0
            self.end = base.borders.count
        }

        public mutating func next() -> Label? {
            if self.start >= self.end {
                return nil
            }

            /// self.name.borders.count is self.end based on the initializer,
            /// so no need to check again for that.
            let end = self.name.borders[self.start]
            let start: UInt8 =
                switch self.start {
                case 0: 0
                default: self.name.borders[self.start - 1]
                }
            self.start += 1

            var bytes: [UInt8] = []
            /// TODO: make sure this is safe
            bytes.reserveCapacity(Int(end - start))
            for idx in start..<end {
                bytes.append(self.name.data[Int(idx)])
            }

            return bytes
        }
    }

    public func makeIterator() -> Self.Iterator {
        Iterator(base: self)
    }
}

extension Name {
    @usableFromInline
    enum ParsingState: ~Copyable {
        case label
        case escape1
        case escape2(UInt8)
        case escape3(UInt8, UInt8)
    }

    /// Parses the name from the string, and ensures the name is valid.
    /// Example: try Name(string: "mahdibm.com")
    @inlinable
    public init(string: String, origin: Self? = nil) throws {
        self.init()

        // short circuit root parse
        /// TODO: do we need `.utf8` here?
        if string.utf8.count == 1, string.utf8.first == UInt8.asciiDot {
            self.isFQDN = true
            return
        }

        var scalars = string.unicodeScalars
        Name.ensureASCII(&scalars)
        try self.init(
            guaranteedASCIIBytes: scalars.flatMap(\.utf8),
            origin: origin
        )
    }

    @usableFromInline
    init(expectingASCIIBytes bytes: some Collection<UInt8>, name: StaticString) throws {
        guard bytes.allSatisfy(\.isASCII) else {
            /// FIXME: throw a better error
            throw ProtocolError.failedToValidate(name, DNSBuffer(bytes: bytes))
        }
        self.init()
        try self.init(guaranteedASCIIBytes: bytes)
    }

    @usableFromInline
    init(
        guaranteedASCIIBytes bytes: some Collection<UInt8>,
        origin: Self? = nil
    ) throws {
        self.init()
        var label = [UInt8]()
        /// FIXME: try this line after we have benchmarks
        // label.reserveCapacity(8)

        var state: ParsingState = .label

        for char in bytes {
            state = try self.iterate(
                state: state,
                label: &label,
                char: char,
                bytes: bytes
            )
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

    @usableFromInline
    mutating func iterate(
        state: consuming ParsingState,
        label: inout [UInt8],
        char: UInt8,
        bytes: some Collection<UInt8>
    ) throws -> ParsingState {
        switch consume state {
        case .label:
            switch char {
            case UInt8.asciiDot:
                if label.isEmpty {
                    throw ProtocolError.failedToValidate("Name.bytes", DNSBuffer(bytes: bytes))
                }
                try self.extendName(label)
                label.removeAll(keepingCapacity: true)
                return .label
            case UInt8.asciiBackslash:
                return .escape1
            case let char
            where Unicode.Scalar(char).properties.generalCategory != .control
                && !Unicode.Scalar(char).properties.isWhitespace:
                label.append(char)
                return .label
            default:
                throw ProtocolError.badCharacter(
                    in: "Name.bytes",
                    character: char,
                    DNSBuffer(bytes: bytes)
                )
            }
        case .escape1:
            if Unicode.Scalar(char).properties.generalCategory.isNumeric {
                return .escape2(char)
            } else {
                /// it's a single escaped char
                label.append(char)
                return .label
            }
        case .escape2(let i):
            if Unicode.Scalar(char).properties.generalCategory.isNumeric {
                return .escape3(i, char)
            } else {
                throw ProtocolError.badCharacter(
                    in: "Name.bytes",
                    character: char,
                    DNSBuffer(bytes: bytes)
                )
            }
        case .escape3(let i, let ii):
            guard Unicode.Scalar(char).properties.generalCategory.isNumeric else {
                throw ProtocolError.badCharacter(
                    in: "Name.bytes",
                    character: char,
                    DNSBuffer(bytes: bytes)
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
                    DNSBuffer(bytes: bytes)
                )
            }
            label.append(contentsOf: new.utf8)
            return .label
        }
    }

    @usableFromInline
    mutating func appendDomain(_ domain: Self) throws {
        try self.appendName(domain)
        self.isFQDN = true
    }

    @usableFromInline
    mutating func appendName(_ name: Self) throws {
        for label in name {
            try self.extendName(label)
        }
        self.isFQDN = name.isFQDN
    }

    /// Extend the name with the offered label, and ensure maximum name length is not exceeded.
    /// Does not check if the label is not empty. That needs to be checked by the caller.
    /// In the wire format labels cannot be empty, but in the string format they can, so the caller
    /// will need to check that.
    @usableFromInline
    mutating func extendName(_ label: [UInt8]) throws {
        let newLength = self.encodedLength + label.count + 1

        if newLength > Self.maxLength {
            throw ProtocolError.lengthLimitExceeded(
                "Name.label",
                actual: newLength,
                max: Int(Self.maxLength),
                DNSBuffer(bytes: label)
            )
        }

        self.data.append(contentsOf: label)
        self.borders.append(
            /// Safe to force unwrap because already checked newLength is
            /// less than Self.maxLength which is 255
            UInt8(exactly: self.data.count)!
        )
    }

    /// Makes sure the bytes are ASCII or turns them into ASCII following IDN.
    /// [RFC 5891, Internationalized Domain Names in Applications (IDNA): Protocol, August 2010](https://datatracker.ietf.org/doc/html/rfc5891)
    @usableFromInline
    static func ensureASCII(_ bytes: inout String.UnicodeScalarView) {
        // let string = ""
        // string.lazy.split(separator: ".")
        guard bytes.contains(where: { !$0.isASCII }) else {
            return
        }

    }

    @usableFromInline
    static func ensureASCIILabel(_ string: inout String) {
        /// [RFC 5891, Internationalized Domain Names in Applications (IDNA): Protocol, August 2010](https://datatracker.ietf.org/doc/html/rfc5891#section-4.1)
        ///
        /// ```text
        /// By the time a string enters the IDNA registration process as
        /// described in this specification, it MUST be in Unicode and in
        /// Normalization Form C (NFC [Unicode-UAX15]).
        /// ```
        let string = string.asNFC

        let scalars = string.unicodeScalars

        /// [RFC 5891, Internationalized Domain Names in Applications (IDNA): Protocol, August 2010](https://datatracker.ietf.org/doc/html/rfc5891#section-4.2.3.1)
        ///
        /// ```text
        /// The Unicode string MUST NOT contain "--" (two consecutive hyphens) in
        /// the third and fourth character positions and MUST NOT start or end
        /// with a "-" (hyphen).
        /// ```
        if (scalars.first?.isHyphen == true)
            || (scalars.last?.isHyphen == true)
            || (scalars.count > 3
                && scalars[scalars.index(scalars.startIndex, offsetBy: 2)].isHyphen
                && scalars[scalars.index(scalars.startIndex, offsetBy: 3)].isHyphen)
        {
            // throw
        }

        /// [RFC 5891, Internationalized Domain Names in Applications (IDNA): Protocol, August 2010](https://datatracker.ietf.org/doc/html/rfc5891#section-4.2.3.2)
        ///
        /// ```text
        /// The Unicode string MUST NOT begin with a combining mark or combining
        /// character (see The Unicode Standard, Section 2.11 [Unicode] for an
        /// exact definition).
        /// ```
        if scalars.first?.properties.generalCategory.isMark == true {
            // throw
        }
        // TODO: check for other IDNA rules
    }
}

extension Name {
    /// This is the list of states for the label parsing state machine
    enum LabelParsingState: ~Copyable {
        case labelLengthOrPointer  // basically the start of the FSM
        case label  // storing length of the label, must be < 63
        case pointer  // location of pointer in slice,
        case root  // root is the end of the labels list for an FQDN
    }

    package init(from buffer: inout DNSBuffer) throws {
        self.init()
        try self.read(from: &buffer)
    }

    /// Reads the domain name from the buffer, adding it to the current name.
    package mutating func read(from buffer: inout DNSBuffer) throws {
        var state: LabelParsingState = .labelLengthOrPointer
        // assume all chars are utf-8. We're doing byte-by-byte operations, no endianness issues...
        // reserved: (1000 0000 aka 0800) && (0100 0000 aka 0400)
        // pointer: (slice == 1100 0000 aka C0) & C0 == true, then 03FF & slice = offset
        // label: 03FF & slice = length slice.next(length) = label
        // root: 0000
        loop: while true {
            switch consume state {
            case .labelLengthOrPointer:
                // determine what the next label is
                switch buffer.peekInteger(as: UInt8.self) {
                case 0:
                    // RFC 1035 Section 3.1 - Name space definitions
                    //
                    // Domain names in messages are expressed in terms of a sequence of labels.
                    // Each label is represented as a one octet length field followed by that
                    // number of octets.  **Since every domain name ends with the null label of
                    // the root, a domain name is terminated by a length byte of zero.**  The
                    // high order two bits of every length octet must be zero, and the
                    // remaining six bits of the length field limit the label to 63 octets or
                    // less.
                    self.isFQDN = true
                    state = .root
                case .none:
                    // Valid names on the wire should end in a 0-octet, signifying the end of
                    // the name. If the last byte wasn't 00, the name is invalid.
                    throw ProtocolError.failedToValidate("Name.label", buffer)
                case .some(let byte):
                    switch byte & 0b1100_0000 {
                    case 0b1100_0000:
                        state = .pointer
                    case 0b0000_0000:
                        state = .label
                    default:
                        throw ProtocolError.badCharacter(
                            in: "Name.label",
                            character: byte,
                            buffer
                        )
                    }
                }
            case .label:
                let label = try buffer.readLengthPrefixedString(
                    name: "Name.label",
                    decodeLengthAs: UInt8.self
                )
                guard label.count <= Self.maxLabelLength else {
                    throw ProtocolError.lengthLimitExceeded(
                        "Name.label",
                        actual: label.count,
                        max: Int(Self.maxLabelLength),
                        buffer
                    )
                }

                /// Label length cannot be zero so we're good to call `extendName`. If the label
                /// length was specified as zero on the wire, that zero would have been taken as the
                /// null byte aka the end of the name, and this code path would not have been taken.
                try self.extendName(label)

                // reset to collect more data
                state = .labelLengthOrPointer
            //         4.1.4. Message compression
            //
            // In order to reduce the size of messages, the domain system utilizes a
            // compression scheme which eliminates the repetition of domain names in a
            // message.  In this scheme, an entire domain name or a list of labels at
            // the end of a domain name is replaced with a pointer to a prior occurrence
            // of the same name.
            //
            // The pointer takes the form of a two octet sequence:
            //
            //     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
            //     | 1  1|                OFFSET                   |
            //     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
            //
            // The first two bits are ones.  This allows a pointer to be distinguished
            // from a label, since the label must begin with two zero bits because
            // labels are restricted to 63 octets or less.  (The 10 and 01 combinations
            // are reserved for future use.)  The OFFSET field specifies an offset from
            // the start of the message (i.e., the first octet of the ID field in the
            // domain header).  A zero offset specifies the first byte of the ID field,
            // etc.
            case .pointer:
                let pointer = try buffer.readInteger(as: UInt16.self).unwrap(
                    or: .failedToRead("Name.label", buffer)
                )
                let currentIndex = buffer.readerIndex
                let offset = pointer & 0b0011_1111_1111_1111

                /// FIXME: check offset is not out of bounds
                /// TODO: use a cache of some sort to avoid re-parsing the same name multiple times
                buffer.moveReaderIndex(toOffsetInDNSPortion: Int(offset))
                try self.read(from: &buffer)
                /// Reset the reader index to where we were
                /// There is no null byte at the end, for pointers
                buffer.moveReaderIndex(to: currentIndex)

                // Pointers always finish the name, break like Root.
                break loop
            case .root:
                assert(buffer.peekInteger(as: UInt8.self) == 0)
                buffer.moveReaderIndex(forwardBy: 1)
                break loop
            }
        }

        // TODO: should we consider checking this while the name is parsed?
        let len = self.encodedLength
        if len >= Self.maxLength {
            throw ProtocolError.lengthLimitExceeded(
                "Name",
                actual: len,
                max: Int(Self.maxLength),
                buffer
            )
        }
    }
}

extension Name: CustomStringConvertible {
    public var description: String {
        var scalars: [Unicode.Scalar] = []
        scalars.reserveCapacity(self.encodedLength)

        var iterator = self.makeIterator()
        if let first = iterator.next() {
            scalars.append(contentsOf: first.map(Unicode.Scalar.init))
        }

        while let label = iterator.next() {
            scalars.append(".")
            scalars.append(contentsOf: label.map(Unicode.Scalar.init))
        }

        if self.isFQDN {
            scalars.append(".")
        }

        return String(String.UnicodeScalarView(scalars))
    }
}

extension Name {
    package func encode(into buffer: inout DNSBuffer, asCanonical: Bool = false) throws {
        let startingReadableBytes = buffer.readableBytes

        for label in self {
            try buffer.writeLengthPrefixedString(
                name: "Name.labels[]",
                bytes: label,
                maxLength: Self.maxLabelLength,
                fitLengthInto: UInt8.self
            )
        }

        /// Write end
        buffer.writeInteger(0 as UInt8)

        /// lazily assert the size is less than 256...
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
