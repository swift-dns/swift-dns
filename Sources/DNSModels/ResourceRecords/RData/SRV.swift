/// [RFC 2782, DNS SRV RR, February 2000](https://tools.ietf.org/html/rfc2782)
///
/// ```text
/// Introductory example
///
///  If a SRV-cognizant LDAP client wants to discover a LDAP server that
///  supports TCP protocol and provides LDAP service for the domain
///  example.com., it does a lookup of
///
/// _ldap._tcp.example.com
///
///  as described in [ARM].  The example zone file near the end of this
///  memo contains answering RRs for an SRV query.
///
///  Note: LDAP is chosen as an example for illustrative purposes only,
///  and the LDAP examples used in this document should not be considered
///  a definitive statement on the recommended way for LDAP to use SRV
///  records. As described in the earlier applicability section, consult
///  the appropriate LDAP documents for the recommended procedures.
///
/// The format of the SRV RR
///
///  Here is the format of the SRV RR, whose DNS type code is 33:
///
/// _Service._Proto.Name TTL Class SRV Priority Weight Port Target
///
/// (There is an example near the end of this document.)
///
///  Service
/// The symbolic name of the desired service, as defined in Assigned
/// Numbers [STD 2] or locally.  An underscore (_) is prepended to
/// the service identifier to avoid collisions with DNS labels that
/// occur in nature.
///
/// Some widely used services, notably POP, don't have a single
/// universal name.  If Assigned Numbers names the service
/// indicated, that name is the only name which is legal for SRV
/// lookups.  The Service is case insensitive.
///
///  Proto
/// The symbolic name of the desired protocol, with an underscore
/// (_) prepended to prevent collisions with DNS labels that occur
/// in nature.  _TCP and _UDP are at present the most useful values
/// for this field, though any name defined by Assigned Numbers or
/// locally may be used (as for Service).  The Proto is case
/// insensitive.
///
///  Name
/// The domain this RR refers to.  The SRV RR is unique in that the
/// name one searches for is not this name; the example near the end
/// shows this clearly.
///
///  TTL
/// Standard DNS meaning [RFC 1035].
///
///  Class
/// Standard DNS meaning [RFC 1035].   SRV records occur in the IN
/// Class.
///
/// ```
public struct SRV: Sendable {
    public var priority: UInt16
    public var weight: UInt16
    public var port: UInt16
    public var target: Name

    public init(priority: UInt16, weight: UInt16, port: UInt16, target: Name) {
        self.priority = priority
        self.weight = weight
        self.port = port
        self.target = target
    }
}

extension SRV {
    package init(from buffer: inout DNSBuffer) throws {
        self.priority = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("SRV.priority", buffer)
        )
        self.weight = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("SRV.weight", buffer)
        )
        self.port = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("SRV.port", buffer)
        )
        self.target = try Name(from: &buffer)
    }
}

extension SRV {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeInteger(self.priority)
        buffer.writeInteger(self.weight)
        buffer.writeInteger(self.port)
        try self.target.encode(into: &buffer)
    }
}
