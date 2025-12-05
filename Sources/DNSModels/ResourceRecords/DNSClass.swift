/// The DNS Record class
public enum DNSClass: Sendable, Hashable {
    /// Internet
    case IN
    /// Chaos
    case CH
    /// Hesiod
    case HS
    /// QCLASS NONE
    case NONE
    /// QCLASS * (ANY)
    case ANY
    /// Special class for OPT Version, it was overloaded for EDNS - RFC 6891
    /// From the RFC: `Values lower than 512 MUST be treated as equal to 512`
    case OPT(UInt16)
    /// Unknown DNSClass was parsed
    case unknown(UInt16)
}

extension DNSClass: CustomStringConvertible {
    public var description: String {
        switch self {
        case .IN: return "IN"
        case .CH: return "CH"
        case .HS: return "HS"
        case .NONE: return "NONE"
        case .ANY: return "ANY"
        case .OPT(let value): return "OPT(\(value))"
        case .unknown(let value): return "unknown(\(value))"
        }
    }
}

extension DNSClass: RawRepresentable {
    public init(_ rawValue: UInt16) {
        switch rawValue {
        case 1: self = .IN
        case 3: self = .CH
        case 4: self = .HS
        case 254: self = .NONE
        case 255: self = .ANY
        default: self = .unknown(rawValue)
        }
    }

    public init?(rawValue: UInt16) {
        self.init(rawValue)
    }

    public var rawValue: UInt16 {
        switch self {
        case .IN: return 1
        case .CH: return 3
        case .HS: return 4
        case .NONE: return 254
        case .ANY: return 255
        case .OPT(let value): return value
        case .unknown(let value): return value
        }
    }
}

extension DNSClass {
    init(forOPT rawValue: UInt16) {
        // From RFC 6891: `Values lower than 512 MUST be treated as equal to 512`
        let value = max(rawValue, 512)
        self = .OPT(value)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension DNSClass {
    package init(from buffer: inout DNSBuffer) throws {
        let dnsClass = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("DNSClass", buffer)
        )
        self = DNSClass(dnsClass)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension DNSClass {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}
