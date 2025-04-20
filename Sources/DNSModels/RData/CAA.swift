/// The CAA RR Type
///
/// [RFC 8659, DNS Certification Authority Authorization, November 2019](https://www.rfc-editor.org/rfc/rfc8659)
@available(macOS 9999, *)
public struct CAA {
    /// Specifies in what contexts this key may be trusted for use
    public enum Property {
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
    @available(macOS 9999, *)
    public enum Value {
        /// Issuer authorized to issue certs for this zone, and any associated parameters
        case issuer(Name?, KeyValuePairs<String, String>)
        /// Url to which to send CA errors
        case url(String)
        /// Uninterpreted data, either for a tag that is not known, or an invalid value
        case unknown([UInt8])
    }

    public let issuerCritical: Bool
    public let reservedFlags: UInt8
    public let tag: Property
    public let value: Value
    public let rawValue: [UInt8]
}
