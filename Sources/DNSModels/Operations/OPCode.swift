/// Operation code for queries, updates, and responses
///
/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
///
/// ```text
/// OPCODE          A four bit field that specifies kind of query in this
///                 message.  This value is set by the originator of a query
///                 and copied into the response.  The values are:
///
///                 0               a standard query (QUERY)
///
///                 1               an inverse query (IQUERY)
///
///                 2               a server status request (STATUS)
///
///                 3-15            reserved for future use
/// ```
/// Some OPCodes are defined in later RFCs, and some are deprecated.
public enum OPCode {
    /// Query request [RFC 1035](https://tools.ietf.org/html/rfc1035)
    case Query
    /// Status message [RFC 1035](https://tools.ietf.org/html/rfc1035)
    case Status
    /// Notify of change [RFC 1996](https://tools.ietf.org/html/rfc1996)
    case Notify
    /// Update message [RFC 2136](https://tools.ietf.org/html/rfc2136)
    case Update
    /// DNS Stateful Operations message [RFC 8499](https://tools.ietf.org/html/rfc8499)
    case DSO
    /// Any other opcode
    case unknown(UInt8)
}

extension OPCode: RawRepresentable {
    public init?(rawValue: UInt8) {
        switch rawValue {
        case 0: self = .Query
        case 2: self = .Status
        case 4: self = .Notify
        case 5: self = .Update
        case 6: self = .DSO
        case 1, 3, 7...15: self = .unknown(rawValue)
        default: return nil
        }
    }

    public var rawValue: UInt8 {
        switch self {
        case .Query: return 0
        case .Status: return 2
        case .Notify: return 4
        case .Update: return 5
        case .DSO: return 6
        case .unknown(let value): return value
        }
    }
}
