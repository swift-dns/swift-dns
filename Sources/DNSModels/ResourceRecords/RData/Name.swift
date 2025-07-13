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
    /// The data of each label in the name. ASCII bytes only.
    /// non-ASCII names are converted to ASCII based on the IDNA spec, in the initializers, and
    /// will never make it to the stored properties of `Name` such as `data`.
    ///
    /// [RFC 9499, DNS Terminology, March 2024](https://tools.ietf.org/html/rfc9499)
    ///
    /// ```text
    /// 2.1.12 Label
    ///
    /// An ordered list of zero or more octets that makes up a portion of a domain name.
    /// Using graph theory, a label identifies one node in a portion of the graph of all possible domain names.
    /// ```
    /// FIXME: investigate performance improvements, with something like `ArraySlice<UInt8>` or `TinyVec`
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

    /// Case-sensitive domain name equality check.
    /// Use `==` for a case-insensitive check.
    @inlinable
    public func exactlyEquals(_ other: Self) -> Bool {
        self.isFQDN == other.isFQDN
            && self.borders == other.borders
            && self.data == other.data
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

    /// Parses and case-folds the name from the string, and ensures the name is valid.
    /// Example: try Name(domainName: "mahdibm.com")
    /// Converts the domain name to ASCII if it's not already according to the IDNA spec.
    @inlinable
    public init(domainName: String, idnaConfiguration: IDNA.Configuration = .default) throws {
        self.init()

        // short circuit root parse
        if domainName.unicodeScalars.count == 1,
            domainName.unicodeScalars.first == Unicode.Scalar.asciiDot
        {
            self.isFQDN = true
            return
        }

        var domainName = domainName

        /// Remove the trailing dot if it exists, and set the FQDN flag
        /// The IDNA spec doesn't like the root label separator.
        if domainName.unicodeScalars.last?.isIDNALabelSeparator == true {
            self.isFQDN = true
            domainName = String(domainName.unicodeScalars.dropLast())
        }

        /// short-circuit most domain names which won't change with IDNA anyway.
        if domainName.unicodeScalars.contains(where: { !$0.isGuaranteedIDNANoOpCharacter }) {
            try IDNA(
                configuration: idnaConfiguration
            ).toASCII(
                domainName: &domainName
            )
        } else {
            /// Make sure the domain name is normalized in lowercase.
            domainName = domainName.guaranteedASCIIStringToLowercase()
        }

        try Self.from(guaranteedASCIIBytes: domainName.utf8, into: &self)
    }

    @usableFromInline
    init(expectingASCIIBytes bytes: some Collection<UInt8>, name: StaticString) throws {
        guard bytes.allSatisfy(\.isASCII) else {
            /// FIXME: throw a better error
            throw ProtocolError.failedToValidate(name, DNSBuffer(bytes: bytes))
        }
        self.init()
        try Self.from(guaranteedASCIIBytes: bytes, into: &self)
    }

    @usableFromInline
    init(guaranteedASCIIBytes bytes: some Collection<UInt8>) throws {
        self.init()
        try Self.from(guaranteedASCIIBytes: bytes, into: &self)
    }

    @usableFromInline
    static func from(
        guaranteedASCIIBytes bytes: some Collection<UInt8>,
        into name: inout Name
    ) throws {
        assert(bytes.allSatisfy(\.isASCII))

        name.data.reserveCapacity(Int(bytes.count))
        /// FIXME: is 4 a good number of bytes to reserve capacity for?
        name.borders.reserveCapacity(4)
        for label in bytes.split(separator: .asciiDot, omittingEmptySubsequences: false) {
            guard !label.isEmpty else {
                /// FIXME: throw a better error
                throw ProtocolError.failedToValidate("Name", DNSBuffer(bytes: bytes))
            }
            try name.extendName(Array(label))
        }
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
        /// Attempt to repair the domain name if it was not ASCII
        if data.contains(where: { !$0.isASCII }) {
            let description = self.description(format: .unicode, options: .sourceAccurate)
            self = try Self.init(domainName: description)
        }
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

        /// TODO: should we consider checking this while the name is parsed?
        /// TODO: `> Self.maxLength {` is correct or `>= Self.maxLength {`?
        let len = self.encodedLength
        if len > Self.maxLength {
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
    /// Unicode-friendly description of the domain name, excluding the possible root label separator.
    public var description: String {
        self.description(format: .unicode)
    }
}

extension Name: CustomDebugStringConvertible {
    /// Byte-accurate description of the domain name.
    public var debugDescription: String {
        self.description(format: .ascii, options: .includeRootLabelIndicator)
    }
}

extension Name {
    /// FIXME: public nonfrozen enum
    public enum DescriptionFormat {
        case ascii
        case unicode
    }

    public struct DescriptionOptions: OptionSet {
        public var rawValue: Int

        @inlinable
        public static var includeRootLabelIndicator: Self {
            Self(rawValue: 1 << 0)
        }

        @inlinable
        public static var sourceAccurate: Self {
            .includeRootLabelIndicator
        }

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public func description(
        format: DescriptionFormat,
        options: DescriptionOptions = []
    ) -> String {
        var scalars: [Unicode.Scalar] = []
        scalars.reserveCapacity(self.encodedLength)

        var iterator = self.makeIterator()
        if let firstLabel = iterator.next() {
            scalars.append(contentsOf: firstLabel.map(Unicode.Scalar.init))
        }

        while let label = iterator.next() {
            scalars.append(".")
            scalars.append(contentsOf: label.map(Unicode.Scalar.init))
        }

        var domainName = String(String.UnicodeScalarView(scalars))

        if format == .unicode {
            do {
                try IDNA(configuration: .mostLax)
                    .toUnicode(domainName: &domainName)
            } catch {
                domainName = String(String.UnicodeScalarView(scalars))
            }
        }

        if self.isFQDN,
            options.contains(.includeRootLabelIndicator)
        {
            domainName.append(".")
        }

        return domainName
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

extension String {
    @usableFromInline
    func guaranteedASCIIStringToLowercase() -> String {
        assert(self.allSatisfy(\.isASCII))
        return String(
            String.UnicodeScalarView(
                self.unicodeScalars.map {
                    /// https://ss64.com/ascii.html
                    /// The difference between an upper and lower cased ASCII byte is their sixth bit.
                    /// Turn the sixth bit on to ensure lowercased ASCII byte.
                    Unicode.Scalar($0.value | 0b0010_0000)!
                }
            )
        )
    }
}
