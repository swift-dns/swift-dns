public import SwiftIDNA

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
    /// The data of each label in the name. Lowercased ASCII bytes only.
    /// non-ASCII names are converted to ASCII based on the IDNA spec, in the initializers, and
    /// will never make it to the stored properties of `Name` such as `data`.
    /// non-lowercased ASCII names are converted to lowercase ASCII in the initializers.
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

        /// Make sure the name is valid
        /// No empty labels
        assert(self.allSatisfy({ !$0.isEmpty }))
        assert(self.data.allSatisfy(\.isASCII))
        assert(self.data.allSatisfy { $0.uncheckedASCIIToLowercase() == $0 })
    }
}

extension Name {
    @inlinable
    public static var root: Self {
        Self(isFQDN: true, data: [], borders: [])
    }
}

extension Name: Hashable {
    /// Equality check without considering the FQDN flag.
    /// Users usually instantiate `Name` using a domain name which doesn't end in a dot.
    /// That mean user-instantiate `Name`s usually have `isFQDN` set to `false`.
    /// On the wire though, the root label is almost always present, so `isFQDN` is almost always `true`.
    /// So this method is useful to make sure a comparison of two `Name`s doesn't fail just because
    /// of the root-label indicator / FQN flag.
    public func isEssentiallyEqual(to other: Self) -> Bool {
        self.data == other.data && self.borders == other.borders
    }
}

extension Name: Sequence {
    public struct Iterator: IteratorProtocol {
        public typealias Label = [UInt8]

        let name: Name
        var start: Int
        let end: Int

        init(base: Name) {
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

        /// TODO: make sure all initializations of Name go through a single initializer that
        /// asserts lowercased ASCII?

        /// short-circuit most domain names which won't change with IDNA anyway.
        try IDNA(
            configuration: idnaConfiguration
        ).toASCII(
            domainName: &domainName
        )

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

    @usableFromInline
    mutating func extendNameReadingFromBuffer(_ buffer: inout DNSBuffer) throws {
        let currentLength = self.encodedLength
        try buffer.readLengthPrefixedString(
            name: "Name.label",
            decodeLengthAs: UInt8.self,
            into: &self.data,
            performLengthCheck: { labelLength, buffer in

                guard labelLength <= Self.maxLabelLength else {
                    throw ProtocolError.lengthLimitExceeded(
                        "Name.label",
                        actual: Int(labelLength),
                        max: Int(Self.maxLabelLength),
                        buffer
                    )
                }

                let newLength = currentLength + Int(labelLength) + 1

                if newLength > Self.maxLength {
                    throw ProtocolError.lengthLimitExceeded(
                        "Name.label",
                        actual: newLength,
                        max: Int(Self.maxLength),
                        buffer
                    )
                }
            }
        )

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

    /// `knownLength` is the length of the name in bytes including the null byte, if known.
    package init(from buffer: inout DNSBuffer, knownLength: Int? = nil) throws {
        self.init()
        try self.read(from: &buffer, knownLength: knownLength)

        switch self.performASCIICheck() {
        case .containsOnlyASCII:
            break
        case .isASCIIButContainsUppercasedLetters:
            /// Normalize to lowercase ASCII
            self.data = self.data.map {
                $0.uncheckedASCIIToLowercase()
            }
        case .containsNonASCII:
            /// Attempt to repair the domain name if it was not ASCII.
            /// non-ASCII bytes are technically not allowed in DNS.
            let description = self.utf8Representation()
            self = try Self.init(domainName: description)
        }
    }

    /// Reads the domain name from the buffer, adding it to the current name.
    /// `knownLength` is the length of the name in bytes including the null byte, if known.
    package mutating func read(
        from buffer: inout DNSBuffer,
        knownLength: Int?
    ) throws {
        var state: LabelParsingState = .labelLengthOrPointer
        // assume all chars are utf-8. We're doing byte-by-byte operations, no endianness issues...
        // reserved: (1000 0000 aka 0800) && (0100 0000 aka 0400)
        // pointer: (slice == 1100 0000 aka C0) & C0 == true, then 03FF & slice = offset
        // label: 03FF & slice = length slice.next(length) = label
        // root: 0000
        var firstLabel = true
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

                        if firstLabel {
                            firstLabel = false

                            if let knownLength = knownLength,
                                knownLength <= UInt8.max,
                                knownLength > 0/// At least a null byte needs to be present
                            {
                                /// Excluding the null byte, we have `knownLength - 1` bytes that are either
                                /// <character-string>s which is to say they are either a length-byte or the
                                /// actual label bytes. Worst case we have `(knownLength - 1) / 2` label bytes.
                                /// label bytes are added to `data`, so we can reserve some capacity there.
                                /// We also reserve capacity for borders. There is a border for each label-length byte.
                                ///
                                /// Based on my simple weighted average calculations using Cloudflare's top 1M domains,
                                /// the weighted-average ratio of label-bytes to domain-length is 0.915,
                                /// and the weighted-average ratio of labels to domain-length is 0.165.
                                /// so we reserve the bytes below based on those ratios.
                                /// Based on the same analysis, the weighted-average number of label-bytes per
                                /// domain is 12.75. Also the weighted-average number of labels per domain is 2.07.
                                ///
                                /// We only reserve `data` bytes because label-counts which correspond
                                /// to `borders` are usually very few.
                                let knownLengthNoNullByte = knownLength - 1
                                let labelBytesProjection = Int(knownLengthNoNullByte) * 92 / 100
                                /// Only reserve if the projection is greater than 16 bytes.
                                /// Otherwise the first allocation will reserve 16 bytes anyway.
                                if labelBytesProjection > 16 {
                                    let maxPossibleLabelBytes = Int(UInt8.max - 1)
                                    let dataProjectedRequiredCapacity = Swift.min(
                                        labelBytesProjection,
                                        maxPossibleLabelBytes
                                    )
                                    self.data.reserveCapacity(dataProjectedRequiredCapacity)
                                }
                            }
                        }
                    default:
                        throw ProtocolError.badCharacter(
                            in: "Name.label",
                            character: byte,
                            buffer
                        )
                    }
                }
            case .label:
                try self.extendNameReadingFromBuffer(&buffer)

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

                /// TODO: use a cache of some sort to avoid re-parsing the same name multiple times
                guard buffer.moveReaderIndex(toOffsetInDNSPortion: offset) else {
                    throw ProtocolError.failedToValidate("Name.label.offset", buffer)
                }
                try self.read(from: &buffer, knownLength: nil)
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

    private func utf8Representation() -> String {
        var name = self.map {
            String(decoding: $0, as: UTF8.self)
        }.joined(separator: ".")
        if self.isFQDN {
            name.append(".")
        }
        return name
    }

    enum ASCIICheckResult {
        case containsOnlyASCII
        case isASCIIButContainsUppercasedLetters
        case containsNonASCII
    }

    func performASCIICheck() -> ASCIICheckResult {
        var containsUppercased = false

        for byte in self.data {
            if byte.isUppercasedASCII {
                containsUppercased = true
            } else if byte.isASCII {
                continue
            } else {
                return .containsNonASCII
            }
        }

        return containsUppercased ? .isASCIIButContainsUppercasedLetters : .containsOnlyASCII
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
        /// ASCII-only description of the domain name, as in the wire format and IDNA.
        case ascii
        /// Unicode representation of the domain name, converting IDNA names to Unicode.
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
