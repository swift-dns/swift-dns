/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987][rfc1035]
///
/// ```text
/// 3.3.2. HINFO RDATA format
///
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     /                      CPU                      /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     /                       OS                      /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
/// where:
///
/// CPU             A <character-string> which specifies the CPU type.
///
/// OS              A <character-string> which specifies the operating
///                 system type.
///
/// Standard values for CPU and OS can be found in [RFC-1010].
///
/// HINFO records are used to acquire general information about a host.  The
/// main use is for protocols such as FTP that can use special procedures
/// when talking between machines or operating systems of the same type.
/// ```
///
/// [rfc1035]: https://tools.ietf.org/html/rfc1035
public struct HINFO {
    public let cpu: String
    public let os: String
}
