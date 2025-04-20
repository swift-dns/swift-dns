/// [RFC 7929](https://tools.ietf.org/html/rfc7929#section-2.1)
///
/// ```text
/// The RDATA portion of an OPENPGPKEY resource record contains a single
/// value consisting of a Transferable Public Key formatted as specified
/// in [RFC4880].
/// ```
@available(macOS 9999, *)
public struct OPENPGPKEY {
    public let publicKey: [UInt8]
}
