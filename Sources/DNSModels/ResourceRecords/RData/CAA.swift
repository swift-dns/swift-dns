public import struct NIOCore.ByteBuffer

/// The CAA RR Type
///
/// [RFC 8659, DNS Certification Authority Authorization, November 2019](https://www.rfc-editor.org/rfc/rfc8659)
public struct CAA: Sendable, Equatable {
    /// Specifies in what contexts this key may be trusted for use
    public enum Property: Sendable, Equatable {
        /// The issue property
        ///    entry authorizes the holder of the domain name `Issuer Domain
        ///    Name`` or a party acting under the explicit authority of the holder
        ///    of that domain name to issue certificates for the domain in which
        ///    the property is published.
        case issue
        /// The issuewild
        ///    property entry authorizes the holder of the domain name `Issuer
        ///    Domain Name` or a party acting under the explicit authority of the
        ///    holder of that domain name to issue wildcard certificates for the
        ///    domain in which the property is published.
        case issueWildcard
        /// Specifies a URL to which an issuer MAY report
        ///    certificate issue requests that are inconsistent with the issuer's
        ///    Certification Practices or Certificate Policy, or that a
        ///    Certificate Evaluator may use to report observation of a possible
        ///    policy violation. The Incident Object Description Exchange Format
        ///    (IODEF) format is used [RFC7970](https://www.rfc-editor.org/rfc/rfc7970).
        case iodef
        /// An unknown property
        case unknown(String)
    }

    /// Potential values.
    ///
    /// These are based off the Tag field:
    ///
    /// `Issue` and `IssueWild` => `Issuer`,
    /// `Iodef` => `Url`,
    /// `Unknown` => `Unknown`.
    ///
    /// `Unknown` is also used for invalid values of known Tag types that cannot be parsed.
    public enum Value: Sendable, Equatable {
        /// Issuer authorized to issue certs for this zone, and any associated parameters
        case issuer(Name?, [(key: String, value: String)])
        /// Url to which to send CA errors
        case url(String)
        /// Uninterpreted data, either for a tag that is not known, or an invalid value
        case unknown(ByteBuffer)

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.issuer(let lhsName, let lhsPairs), .issuer(let rhsName, let rhsPairs)):
                return lhsName == rhsName
                    && lhsPairs.lazy.map(\.key) == rhsPairs.lazy.map(\.key)
                    && lhsPairs.lazy.map(\.value) == rhsPairs.lazy.map(\.value)
            case (.url(let lhsUrl), .url(let rhsUrl)):
                return lhsUrl == rhsUrl
            case (.unknown(let lhsData), .unknown(let rhsData)):
                return lhsData == rhsData
            default:
                return false
            }
        }
    }

    public var issuerCritical: Bool
    public var reservedFlags: UInt8
    public var tag: Property
    public var value: Value
    public var rawValue: ByteBuffer

    var flags: UInt8 {
        var flags = self.reservedFlags & 0b0111_1111
        if self.issuerCritical {
            flags |= 0b1000_0000
        }
        return flags
    }

    public init(
        issuerCritical: Bool,
        reservedFlags: UInt8,
        tag: Property,
        value: Value,
        rawValue: ByteBuffer
    ) {
        self.issuerCritical = issuerCritical
        self.reservedFlags = reservedFlags
        self.tag = tag
        self.value = value
        self.rawValue = rawValue
    }
}

extension CAA {
    package init(from buffer: inout DNSBuffer) throws {
        /// TODO: move flags to how Bytes16To31 handles flags
        let flags = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("CAA.flags", buffer)
        )
        self.issuerCritical = (flags & 0b1000_0000) != 0
        self.reservedFlags = flags & 0b0111_1111
        self.tag = try Property(from: &buffer)
        /// Copy bytes to rawValue, then decode value:
        self.rawValue = buffer.getToEnd()
        self.value = try Value(from: &buffer, tag: self.tag)
    }
}

extension CAA {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeInteger(self.flags)
        var tagBuffer = DNSBuffer()
        self.tag.encode(into: &tagBuffer)
        buffer.writeBuffer(self.rawValue)
    }
}

extension CAA.Property: RawRepresentable {
    public init(_ rawValue: String) {
        switch rawValue {
        case "issue":
            self = .issue
        case "issuewild":
            self = .issueWildcard
        case "iodef":
            self = .iodef
        default:
            self = .unknown(rawValue)
        }
    }

    public init(rawValue: String) {
        self.init(rawValue)
    }

    public var rawValue: String {
        switch self {
        case .issue:
            return "issue"
        case .issueWildcard:
            return "issuewild"
        case .iodef:
            return "iodef"
        case .unknown(let value):
            return value
        }
    }
}

extension CAA.Property {
    package init(from buffer: inout DNSBuffer) throws {
        let length = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("CAA.Property.length", buffer)
        )
        guard length > 0, length < 16 else {
            throw ProtocolError.failedToValidate("CAA.Property.length", buffer)
        }
        let tag = try buffer.readString(length: Int(length)).unwrap(
            or: .failedToRead("CAA.Property.tag", buffer)
        )

        guard tag.unicodeScalars.allSatisfy(\.isASCIIAlphanumeric) else {
            throw ProtocolError.failedToValidate("CAA.Property.tag", buffer)
        }

        self.init(tag)
    }
}

extension CAA.Property {
    package func encode(into buffer: inout DNSBuffer) {
        var temp = DNSBuffer()
        /// TODO: write a test to make sure `self.rawValue.count` is never bigger than UInt8.max
        temp.writeString(self.rawValue)
        buffer.writeInteger(UInt8(temp.readableBytes))
        buffer.writeBuffer(&temp)
    }
}

extension CAA.Value {
    package init(from buffer: inout DNSBuffer, tag: CAA.Property) throws {
        switch tag {
        case .issue, .issueWildcard:
            let (name, pairs) = try Self.readIssuer(from: &buffer)
            self = .issuer(name, pairs)
        case .iodef:
            self = .url(buffer.readToEndAsString())
        case .unknown:
            self = .unknown(buffer.readToEnd())
        }
    }

    enum ParsingState: ~Copyable {
        case beforeKey([(key: String, value: String)])
        case key(
            isFirstChar: Bool,
            key: String,
            keyValues: [(key: String, value: String)]
        )
        case value(
            key: String,
            value: String,
            keyValues: [(key: String, value: String)]
        )

        var keyValues: [(key: String, value: String)] {
            get throws {
                switch self {
                case let .beforeKey(keyValues):
                    return keyValues
                case .value(let key, let value, var keyValues):
                    keyValues.append((key, value))
                    return keyValues
                case .key(_, let key, _):
                    throw ProtocolError.failedToValidate(
                        "CAA.issuer.state",
                        DNSBuffer(string: key)
                    )
                }
            }
        }
    }

    static func readIssuer(
        from buffer: inout DNSBuffer
    ) throws -> (Name?, [(key: String, value: String)]) {
        let name: Name?
        if let semicolonIdx = buffer.readableBytesView
            .firstIndex(where: { $0 == UInt8.asciiSemicolon })
        {
            /// FXIME: `semicolonIdx - buffer.readerIndex` is safe, right?
            /// FIXME: do "read-while char is not a semicolon"
            let nameBytes = buffer.peekBytes(length: semicolonIdx - buffer.readerIndex) ?? []
            if nameBytes.isEmpty {
                name = nil
            } else {
                name = try Name(
                    expectingASCIIBytes: nameBytes,
                    name: "CAA.issuer.name"
                )
                buffer.moveReaderIndex(forwardBy: nameBytes.count)
            }
        } else {
            if buffer.readableBytes > 0 {
                name = try Name(
                    expectingASCIIBytes: buffer.readableBytesView,
                    name: "CAA.issuer.name"
                )
                buffer.moveReaderIndex(to: buffer.writerIndex)
                /// There was no semicolon in the buffer so the whole of it was the name.
                /// Therefore, we can return immediately.
                return (name, [])
            } else {
                return (nil, [])
            }
        }

        // initial state is looking for a key ';' is valid...
        var state: ParsingState = .beforeKey([])

        // run the state machine through all remaining data, collecting all parameter tag/value pairs.
        while let char = buffer.readInteger(as: UInt8.self) {
            switch consume state {
            // name was already successfully parsed, otherwise we couldn't get here.
            case let .beforeKey(keyValues):
                switch char {
                case UInt8.asciiSemicolon, UInt8.asciiSpace, UInt8.asciiTab:
                    state = .beforeKey(keyValues)
                case let char where char.isASCIIAlphanumeric && (char != UInt8.asciiEqual):
                    /// we found the beginning of a new Key
                    state = .key(
                        isFirstChar: true,
                        key: "\(Unicode.Scalar(char))",
                        keyValues: keyValues
                    )
                default:
                    throw ProtocolError.badCharacter(
                        in: "CAA.issuer.key",
                        character: char,
                        buffer
                    )
                }
            case .key(let isFirstChar, var key, let keyValues):
                switch char {
                /// transition to value
                case UInt8.asciiEqual:
                    state = .value(
                        key: key,
                        value: "",
                        keyValues: keyValues
                    )
                /// push onto the existing key
                case let char
                where (char.isASCIIAlphanumeric || (!isFirstChar && char == UInt8.asciiHyphenMinus))
                    && (char != UInt8.asciiEqual) && (char != UInt8.asciiSemicolon):

                    key.append(Character(Unicode.Scalar(char)))
                    state = .key(
                        isFirstChar: false,
                        key: key,
                        keyValues: keyValues
                    )
                default:
                    throw ProtocolError.badCharacter(
                        in: "CAA.issuer.key",
                        character: char,
                        buffer
                    )
                }
            case .value(let key, var value, var keyValues):
                switch char {
                /// transition back to find another pair
                case UInt8.asciiSemicolon:
                    keyValues.append((key, value))
                    state = .beforeKey(keyValues)
                /// if the next byte is a ASCII printable character, excluding
                /// Space (0x20 == asciiPrintableStart), ';' (0x3B), or
                /// Delete (0x7F == asciiPrintableEnd), push it onto the existing value. See the
                /// ABNF production rule for `parameter-value` in the documentation above.
                case let char
                where char > UInt8.asciiPrintableStart
                    && char < UInt8.asciiPrintableEnd
                    && (char != UInt8.asciiSemicolon):

                    value.append(Character(Unicode.Scalar(char)))
                    state = .value(
                        key: key,
                        value: value,
                        keyValues: keyValues
                    )
                default:
                    throw ProtocolError.badCharacter(
                        in: "CAA.issuer.value",
                        character: char,
                        buffer
                    )
                }
            }
        }

        return (name, try state.keyValues)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension CAA: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .CAA(let caa):
            self = caa
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .CAA(self)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension CAA: Queryable {
    @inlinable
    public static var recordType: RecordType { .CAA }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
