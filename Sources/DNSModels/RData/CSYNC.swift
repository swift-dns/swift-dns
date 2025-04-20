/// [RFC 7477, Child-to-Parent Synchronization in DNS, March 2015][rfc7477]
///
/// ```text
/// 2.1.1.  The CSYNC Resource Record Wire Format
///
/// The CSYNC RDATA consists of the following fields:
///
///                       1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///  |                          SOA Serial                           |
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///  |       Flags                   |            Type Bit Map       /
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///  /                     Type Bit Map (continued)                  /
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// ```
///
/// [rfc7477]: https://tools.ietf.org/html/rfc7477
public struct CSYNC {
    let soaSerial: UInt32
    let immediate: Bool
    let soaMinimum: Bool
    let reservedFlags: UInt16
    let typeBitMaps: RecordTypeSet
}
