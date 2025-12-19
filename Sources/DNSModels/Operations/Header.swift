import DNSCore

/// Metadata for the `Message` struct.
///
/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
///
/// ```text
/// 4.1.1. Header section format
///
/// The header contains the following fields
///
///                                    1  1  1  1  1  1
///      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                      ID                       |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |QR|   Opcode  |AA|TC|RD|RA|ZZ|AD|CD|   RCODE   |  /// AD and CD from RFC4035
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                    QDCOUNT / ZCOUNT           |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                    ANCOUNT / PRCOUNT          |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                    NSCOUNT / UPCOUNT          |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                    ARCOUNT / ADCOUNT          |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
/// where
///
/// Z               Reserved for future use.  Must be zero in all queries
///                 and responses.
///
/// ```
public struct Header: Sendable {
    /// Message types are either Query (also Update) or Response
    @nonexhaustive
    public enum MessageType: UInt8, Sendable {
        /// Queries are Client requests, these are either Queries or Updates
        case Query = 0
        /// Response message from the Server or upstream Resolver
        case Response = 1
    }

    /// Represents Bytes 16 to 31 in the DNS header.
    /// That is, QR, OPCODE, AA, TC, RD, RA, ZZ, AD, CD and RCODE.
    public struct Bytes3And4: Sendable {
        /// private
        public var rawValue: UInt16

        /// TODO: check whether `truncatingIfNeeded` has a positive impact on performance
        /// Compared to just using init().

        public var messageType: MessageType {
            get {
                MessageType(rawValue: UInt8(truncatingIfNeeded: self.rawValue >> 15))!
            }
            set {
                /// clear the 15th bit then set it to the new value
                self.rawValue =
                    (self.rawValue & 0b01111111_11111111)
                    | UInt16(truncatingIfNeeded: newValue.rawValue) &<<< 15
            }
        }
        public var opCode: OPCode {
            get {
                OPCode(rawValue: UInt8((rawValue >> 11) & 0xF))!
            }
            set {
                self.rawValue =
                    (self.rawValue & 0b10000111_11111111)
                    | UInt16(truncatingIfNeeded: newValue.rawValue) &<<< 11
            }
        }
        public var authoritative: Bool {
            get {
                (rawValue & 0b00000100_00000000) == 0b00000100_00000000
            }
            set {
                switch newValue {
                case true: rawValue = (rawValue | 0b00000100_00000000)
                case false: rawValue = (rawValue & 0b11111011_11111111)
                }
            }
        }
        public var truncation: Bool {
            get {
                (rawValue & 0b00000010_00000000) == 0b00000010_00000000
            }
            set {
                switch newValue {
                case true: rawValue = (rawValue | 0b00000010_00000000)
                case false: rawValue = (rawValue & 0b11111101_11111111)
                }
            }
        }
        public var recursionDesired: Bool {
            get {
                (rawValue & 0b00000001_00000000) == 0b00000001_00000000
            }
            set {
                switch newValue {
                case true: rawValue = (rawValue | 0b00000001_00000000)
                case false: rawValue = (rawValue & 0b11111110_11111111)
                }
            }
        }
        public var recursionAvailable: Bool {
            get {
                (rawValue & 0b00000000_10000000) == 0b00000000_10000000
            }
            set {
                switch newValue {
                case true: rawValue = (rawValue | 0b00000000_10000000)
                case false: rawValue = (rawValue & 0b11111111_01111111)
                }
            }
        }
        public var authenticData: Bool {
            get {
                (rawValue & 0b00000000_00100000) == 0b00000000_00100000
            }
            set {
                switch newValue {
                case true: rawValue = (rawValue | 0b00000000_00100000)
                case false: rawValue = (rawValue & 0b11111111_11011111)
                }
            }
        }
        public var checkingDisabled: Bool {
            get {
                (rawValue & 0b00000000_00010000) == 0b00000000_00010000
            }
            set {
                switch newValue {
                case true: rawValue = (rawValue | 0b00000000_00010000)
                case false: rawValue = (rawValue & 0b11111111_11101111)
                }
            }
        }
        public var responseCode: ResponseCode {
            get {
                ResponseCode(rawValue & 0b00000000_00001111)
            }
            set {
                self.rawValue = (self.rawValue & 0b11111111_11110000) | newValue.rawValue
            }
        }

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
    }

    /// A 16 bit identifier assigned by the program that
    /// generates any kind of query. This identifier is copied
    /// the corresponding reply and can be used by the requester
    /// to match up replies to outstanding queries.
    public var id: UInt16

    /// Represents Bytes 16 to 31 in the DNS header.
    /// That is, QR, OPCODE, AA, TC, RD, RA, ZZ, AD, CD and RCODE.
    /// private
    var bytes3And4: Bytes3And4

    /// Whether this message is a query, or a response.
    public var messageType: MessageType {
        get {
            bytes3And4.messageType
        }
        set {
            bytes3And4.messageType = newValue
        }
    }

    /// The kind of query.
    public var opCode: OPCode {
        get {
            bytes3And4.opCode
        }
        set {
            bytes3And4.opCode = newValue
        }
    }

    /// Whether the responding name server is an authority for the domain name in question.
    /// Note that the contents of the answer section may have multiple owner names because of
    /// aliases. `authoritative` corresponds to the domainName which matches the query domainName, or
    /// the first owner domainName in the answer section.
    public var authoritative: Bool {
        get {
            bytes3And4.authoritative
        }
        set {
            bytes3And4.authoritative = newValue
        }
    }

    /// Specifies that this message was truncated due to length greater than that permitted on the
    /// transmission channel.
    public var truncation: Bool {
        get {
            bytes3And4.truncation
        }
        set {
            bytes3And4.truncation = newValue
        }
    }

    /// If true, it directs the name server to pursue the query recursively.
    public var recursionDesired: Bool {
        get {
            bytes3And4.recursionDesired
        }
        set {
            bytes3And4.recursionDesired = newValue
        }
    }

    /// Whether recursive query support is available in the name server.
    public var recursionAvailable: Bool {
        get {
            bytes3And4.recursionAvailable
        }
        set {
            bytes3And4.recursionAvailable = newValue
        }
    }

    /// Whether the data included in the answer and authority portion of the response has been
    /// authenticated by the server according to the policies of that server.
    public var authenticData: Bool {
        get {
            bytes3And4.authenticData
        }
        set {
            bytes3And4.authenticData = newValue
        }
    }

    /// Whether checking is disabled.
    ///
    /// `checkingDisabled` indicates in a query that Pending (non-authenticated) data
    /// is acceptable to the resolver sending the query.
    public var checkingDisabled: Bool {
        get {
            bytes3And4.checkingDisabled
        }
        set {
            bytes3And4.checkingDisabled = newValue
        }
    }

    /// The response code.
    public var responseCode: ResponseCode {
        get {
            bytes3And4.responseCode
        }
        set {
            bytes3And4.responseCode = newValue
        }
    }
    public var queryCount: UInt16
    public var answerCount: UInt16
    public var nameServerCount: UInt16
    public var additionalCount: UInt16

    @usableFromInline
    package init(
        id: UInt16,
        messageType: MessageType,
        opCode: OPCode,
        authoritative: Bool,
        truncation: Bool,
        recursionDesired: Bool,
        recursionAvailable: Bool,
        authenticData: Bool,
        checkingDisabled: Bool,
        responseCode: ResponseCode,
        queryCount: UInt16,
        answerCount: UInt16,
        nameServerCount: UInt16,
        additionalCount: UInt16
    ) {
        self.id = id
        self.queryCount = queryCount
        self.answerCount = answerCount
        self.nameServerCount = nameServerCount
        self.additionalCount = additionalCount

        self.bytes3And4 = Bytes3And4(rawValue: 0)
        self.messageType = messageType
        self.opCode = opCode
        self.authoritative = authoritative
        self.truncation = truncation
        self.recursionDesired = recursionDesired
        self.recursionAvailable = recursionAvailable
        self.authenticData = authenticData
        self.checkingDisabled = checkingDisabled
        self.responseCode = responseCode
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension Header {
    package init(from buffer: inout DNSBuffer) throws {
        self.id = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("Header.id", buffer)
        )
        self.bytes3And4 = try Header.Bytes3And4(from: &buffer)
        self.queryCount = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("Header.queryCount", buffer)
        )
        self.answerCount = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("Header.answerCount", buffer)
        )
        self.nameServerCount = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("Header.nameServerCount", buffer)
        )
        self.additionalCount = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("Header.additionalCount", buffer)
        )
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension Header {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.id)
        self.bytes3And4.encode(into: &buffer)
        buffer.writeInteger(self.queryCount)
        buffer.writeInteger(self.answerCount)
        buffer.writeInteger(self.nameServerCount)
        buffer.writeInteger(self.additionalCount)
    }
}

extension Header.Bytes3And4: CustomStringConvertible {
    public var description: String {
        "Bytes3And4(rawValue: \(self.rawValue), messageType: \(self.messageType), opCode: \(self.opCode), authoritative: \(self.authoritative), truncation: \(self.truncation), recursionDesired: \(self.recursionDesired), recursionAvailable: \(self.recursionAvailable), authenticData: \(self.authenticData), checkingDisabled: \(self.checkingDisabled), responseCode: \(self.responseCode))"
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension Header.Bytes3And4 {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("Header.Bytes3And4.rawValue", buffer)
        )
        self.init(rawValue: rawValue)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension Header.Bytes3And4 {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

extension Header.MessageType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .Query: "Query"
        case .Response: "Response"
        }
    }
}

extension Header.MessageType: CustomDebugStringConvertible {
    public var debugDescription: String {
        "[\(self.rawValue)]\(self.description)"
    }
}
