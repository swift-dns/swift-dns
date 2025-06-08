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
    public enum MessageType: UInt8, Sendable {
        /// Queries are Client requests, these are either Queries or Updates
        case Query = 0
        /// Response message from the Server or upstream Resolver
        case Response = 1
    }

    /// Represents Bytes 16 to 31 in the DNS header.
    /// That is, QR, OPCODE, AA, TC, RD, RA, ZZ, AD, CD and RCODE.
    @_spi(Testing)
    public struct Bytes16To31: Sendable {
        /* private */ public var rawValue: UInt16

        /// TODO: check whether `truncatingIfNeeded` has a positive impact on performance
        /// Compared to just using init().

        public var messageType: MessageType {
            get {
                MessageType(rawValue: UInt8(truncatingIfNeeded: self.rawValue >> 15))!
            }
            set {
                /// clear the 15th bit then set it to the new value
                self.rawValue =
                    (self.rawValue & 0b01111111_11111111) | UInt16(
                        truncatingIfNeeded: newValue.rawValue
                    ) << 15
            }
        }
        public var opCode: OPCode {
            get {
                OPCode(rawValue: UInt8((rawValue >> 11) & 0xF))!
            }
            set {
                self.rawValue =
                    (self.rawValue & 0b10000111_11111111) | UInt16(
                        truncatingIfNeeded: newValue.rawValue
                    ) << 11
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

    public var id: UInt16

    /// Represents Bytes 16 to 31 in the DNS header.
    /// That is, QR, OPCODE, AA, TC, RD, RA, ZZ, AD, CD and RCODE.
    /* private */var bytes16To31: Bytes16To31
    public var messageType: MessageType {
        get {
            bytes16To31.messageType
        }
        set {
            bytes16To31.messageType = newValue
        }
    }
    public var opCode: OPCode {
        get {
            bytes16To31.opCode
        }
        set {
            bytes16To31.opCode = newValue
        }
    }
    public var authoritative: Bool {
        get {
            bytes16To31.authoritative
        }
        set {
            bytes16To31.authoritative = newValue
        }
    }
    public var truncation: Bool {
        get {
            bytes16To31.truncation
        }
        set {
            bytes16To31.truncation = newValue
        }
    }
    public var recursionDesired: Bool {
        get {
            bytes16To31.recursionDesired
        }
        set {
            bytes16To31.recursionDesired = newValue
        }
    }
    public var recursionAvailable: Bool {
        get {
            bytes16To31.recursionAvailable
        }
        set {
            bytes16To31.recursionAvailable = newValue
        }
    }
    public var authenticData: Bool {
        get {
            bytes16To31.authenticData
        }
        set {
            bytes16To31.authenticData = newValue
        }
    }
    public var checkingDisabled: Bool {
        get {
            bytes16To31.checkingDisabled
        }
        set {
            bytes16To31.checkingDisabled = newValue
        }
    }
    public var responseCode: ResponseCode {
        get {
            bytes16To31.responseCode
        }
        set {
            bytes16To31.responseCode = newValue
        }
    }
    public var queryCount: UInt16
    public var answerCount: UInt16
    public var nameServerCount: UInt16
    public var additionalCount: UInt16

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

        self.bytes16To31 = Bytes16To31(rawValue: 0)
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

extension Header {
    package init(from buffer: inout DNSBuffer) throws {
        self.id = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("Header.id", buffer)
        )
        self.bytes16To31 = try Header.Bytes16To31(from: &buffer)
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

extension Header {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.id)
        self.bytes16To31.encode(into: &buffer)
        buffer.writeInteger(self.queryCount)
        buffer.writeInteger(self.answerCount)
        buffer.writeInteger(self.nameServerCount)
        buffer.writeInteger(self.additionalCount)
    }
}

extension Header.Bytes16To31 {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("Header.Bytes16To31.rawValue", buffer)
        )
        self.init(rawValue: rawValue)
    }
}

extension Header.Bytes16To31 {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

/// All the flags of the request/response header
struct Flags: Sendable {
    var authoritative: Bool
    var truncation: Bool
    var recursionDesired: Bool
    var recursionAvailable: Bool
    var authenticData: Bool
    var checkingDisabled: Bool
}
