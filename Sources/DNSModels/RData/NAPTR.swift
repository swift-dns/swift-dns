/// [RFC 3403 DDDS DNS Database, October 2002](https://tools.ietf.org/html/rfc3403#section-4)
///
/// ```text
/// 4.1 Packet Format
///
///   The packet format of the NAPTR RR is given below.  The DNS type code
///   for NAPTR is 35.
///
///      The packet format for the NAPTR record is as follows
///                                       1  1  1  1  1  1
///         0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       |                     ORDER                     |
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       |                   PREFERENCE                  |
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       /                     FLAGS                     /
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       /                   SERVICES                    /
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       /                    REGEXP                     /
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       /                  REPLACEMENT                  /
///       /                                               /
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
///   <character-string> and <domain-name> as used here are defined in RFC
///   1035 [7].
/// ```
@available(macOS 9999, *)
public struct NAPTR {
    public let order: UInt16
    public let preference: UInt16
    public let flags: [UInt8]
    public let services: [UInt8]
    public let regexp: [UInt8]
    public let replacement: Name
}
