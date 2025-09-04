/// The status code of the response to a query.
///
/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
///
/// ```text
/// RCODE           Response code - this 4 bit field is set as part of
///                 responses.  The values have the following
///                 interpretation:
///
///                 0               No error condition
///
///                 1               Format error - The name server was
///                                 unable to interpret the query.
///
///                 2               Server failure - The name server was
///                                 unable to process this query due to a
///                                 problem with the name server.
///
///                 3               DomainName Error - Meaningful only for
///                                 responses from an authoritative name
///                                 server, this code signifies that the
///                                 domain name referenced in the query does
///                                 not exist.
///
///                 4               Not Implemented - The name server does
///                                 not support the requested kind of query.
///
///                 5               Refused - The name server refuses to
///                                 perform the specified operation for
///                                 policy reasons.  For example, a name
///                                 server may not wish to provide the
///                                 information to the particular requester,
///                                 or a name server may not wish to perform
///                                 a particular operation (e.g., zone
///                                 transfer) for particular data.
///
///                 6-15            Reserved for future use.
///  ```
public enum ResponseCode: Sendable {
    /// No Error [RFC 1035](https://tools.ietf.org/html/rfc1035)
    case NoError
    /// Format Error [RFC 1035](https://tools.ietf.org/html/rfc1035)
    case FormErr
    /// Server Failure [RFC 1035](https://tools.ietf.org/html/rfc1035)
    case ServFail
    /// Non-Existent Domain [RFC 1035](https://tools.ietf.org/html/rfc1035)
    case NXDomain
    /// Not Implemented [RFC 1035](https://tools.ietf.org/html/rfc1035)
    case NotImp
    /// Query Refused [RFC 1035](https://tools.ietf.org/html/rfc1035)
    case Refused
    /// DomainName Exists when it should not [RFC 2136](https://tools.ietf.org/html/rfc2136)
    case YXDomain
    /// RR Set Exists when it should not [RFC 2136](https://tools.ietf.org/html/rfc2136)
    case YXRRSet
    /// RR Set that should exist does not [RFC 2136](https://tools.ietf.org/html/rfc2136)
    case NXRRSet
    /// Server Not Authoritative for zone [RFC 2136](https://tools.ietf.org/html/rfc2136)
    /// or Not Authorized [RFC 8945](https://www.rfc-editor.org/rfc/rfc8945)
    case NotAuth
    /// DomainName not contained in zone [RFC 2136](https://tools.ietf.org/html/rfc2136)
    case NotZone
    /// Bad OPT Version [RFC 6891](https://tools.ietf.org/html/rfc6891#section-9)
    case BADVERS
    /// TSIG Signature Failure [RFC 8945](https://www.rfc-editor.org/rfc/rfc8945)
    case BADSIG
    /// Key not recognized [RFC 8945](https://www.rfc-editor.org/rfc/rfc8945)
    case BADKEY
    /// Signature out of time window [RFC 8945](https://www.rfc-editor.org/rfc/rfc8945)
    case BADTIME
    /// Bad TKEY Mode [RFC 2930](https://tools.ietf.org/html/rfc2930#section-2.6)
    case BADMODE
    /// Duplicate key name [RFC 2930](https://tools.ietf.org/html/rfc2930#section-2.6)
    case BADNAME
    /// Algorithm not supported [RFC 2930](https://tools.ietf.org/html/rfc2930#section-2.6)
    case BADALG
    /// Bad Truncation [RFC 4635](https://tools.ietf.org/html/rfc4635#section-4)
    case BADTRUNC
    /// Bad/missing Server Cookie [RFC 7873](https://datatracker.ietf.org/doc/html/rfc7873)
    case BADCOOKIE
    // 24-3840      Unassigned
    // 3841-4095    Reserved for Private Use                        [RFC6895]
    // 4096-65534   Unassigned
    // 65535        Reserved, can be allocated by Standards Action  [RFC6895]
    /// An unknown or unregistered response code was received.
    case unknown(UInt16)
}

extension ResponseCode: RawRepresentable {
    public init(_ rawValue: UInt16) {
        switch rawValue {
        case 0: self = .NoError
        case 1: self = .FormErr
        case 2: self = .ServFail
        case 3: self = .NXDomain
        case 4: self = .NotImp
        case 5: self = .Refused
        case 6: self = .YXDomain
        case 7: self = .YXRRSet
        case 8: self = .NXRRSet
        case 9: self = .NotAuth
        case 10: self = .NotZone
        case 16: self = .BADSIG
        case 17: self = .BADKEY
        case 18: self = .BADTIME
        case 19: self = .BADMODE
        case 20: self = .BADNAME
        case 21: self = .BADALG
        case 22: self = .BADTRUNC
        case 23: self = .BADCOOKIE
        default: self = .unknown(rawValue)
        }
    }

    public init?(rawValue: UInt16) {
        self.init(rawValue)
    }

    public var rawValue: UInt16 {
        switch self {
        case .NoError: return 0
        case .FormErr: return 1
        case .ServFail: return 2
        case .NXDomain: return 3
        case .NotImp: return 4
        case .Refused: return 5
        case .YXDomain: return 6
        case .YXRRSet: return 7
        case .NXRRSet: return 8
        case .NotAuth: return 9
        case .NotZone: return 10
        case .BADSIG, .BADVERS: return 16
        case .BADKEY: return 17
        case .BADTIME: return 18
        case .BADMODE: return 19
        case .BADNAME: return 20
        case .BADALG: return 21
        case .BADTRUNC: return 22
        case .BADCOOKIE: return 23
        case .unknown(let value): return value
        }
    }
}

extension ResponseCode {
    /// TODO: write tests for these

    package var low: UInt8 {
        UInt8(truncatingIfNeeded: self.rawValue & 0x000F)
    }

    package var high: UInt8 {
        UInt8(truncatingIfNeeded: self.rawValue & 0x0FF0)
    }

    package init(high: UInt8, low: UInt8) {
        self.init((UInt16(high) &<< 4) | (UInt16(low) & 0x000F))
    }
}
