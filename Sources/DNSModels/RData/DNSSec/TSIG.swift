/// [RFC 8945, Secret Key Transaction Authentication for DNS](https://tools.ietf.org/html/rfc8945#section-4.2)
///
/// ```text
///   4.2.  TSIG Record Format
///
///   The fields of the TSIG RR are described below.  All multi-octet
///   integers in the record are sent in network byte order (see
///   Section 2.3.2 of [RFC1035]).
///
///   NAME:  The name of the key used, in domain name syntax.  The name
///      should reflect the names of the hosts and uniquely identify the
///      key among a set of keys these two hosts may share at any given
///      time.  For example, if hosts A.site.example and B.example.net
///      share a key, possibilities for the key name include
///      <id>.A.site.example, <id>.B.example.net, and
///      <id>.A.site.example.B.example.net.  It should be possible for more
///      than one key to be in simultaneous use among a set of interacting
///      hosts.  This allows for periodic key rotation as per best
///      operational practices, as well as algorithm agility as indicated
///      by [RFC7696].
///
///      The name may be used as a local index to the key involved, but it
///      is recommended that it be globally unique.  Where a key is just
///      shared between two hosts, its name actually need only be
///      meaningful to them, but it is recommended that the key name be
///      mnemonic and incorporate the names of participating agents or
///      resources as suggested above.
///
///   TYPE:  This MUST be TSIG (250: Transaction SIGnature).
///
///   CLASS:  This MUST be ANY.
///
///   TTL:  This MUST be 0.
///
///   RDLENGTH:  (variable)
///
///   RDATA:  The RDATA for a TSIG RR consists of a number of fields,
///      described below:
///
///                            1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       /                         Algorithm Name                        /
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       |                                                               |
///       |          Time Signed          +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       |                               |            Fudge              |
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       |          MAC Size             |                               /
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+             MAC               /
///       /                                                               /
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       |          Original ID          |            Error              |
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       |          Other Len            |                               /
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+           Other Data          /
///       /                                                               /
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///
///   The contents of the RDATA fields are:
///
///   Algorithm Name:
///      an octet sequence identifying the TSIG algorithm in the domain
///      name syntax.  (Allowed names are listed in Table 3.)  The name is
///      stored in the DNS name wire format as described in [RFC1034].  As
///      per [RFC3597], this name MUST NOT be compressed.
///
///   Time Signed:
///      an unsigned 48-bit integer containing the time the message was
///      signed as seconds since 00:00 on 1970-01-01 UTC, ignoring leap
///      seconds.
///
///   Fudge:
///      an unsigned 16-bit integer specifying the allowed time difference
///      in seconds permitted in the Time Signed field.
///
///   MAC Size:
///      an unsigned 16-bit integer giving the length of the MAC field in
///      octets.  Truncation is indicated by a MAC Size less than the size
///      of the keyed hash produced by the algorithm specified by the
///      Algorithm Name.
///
///   MAC:
///      a sequence of octets whose contents are defined by the TSIG
///      algorithm used, possibly truncated as specified by the MAC Size.
///      The length of this field is given by the MAC Size.  Calculation of
///      the MAC is detailed in Section 4.3.
///
///   Original ID:
///      an unsigned 16-bit integer holding the message ID of the original
///      request message.  For a TSIG RR on a request, it is set equal to
///      the DNS message ID.  In a TSIG attached to a response -- or in
///      cases such as the forwarding of a dynamic update request -- the
///      field contains the ID of the original DNS request.
///
///   Error:
///      in responses, an unsigned 16-bit integer containing the extended
///      RCODE covering TSIG processing.  In requests, this MUST be zero.
///
///   Other Len:
///      an unsigned 16-bit integer specifying the length of the Other Data
///      field in octets.
///
///   Other Data:
///      additional data relevant to the TSIG record.  In responses, this
///      will be empty (i.e., Other Len will be zero) unless the content of
///      the Error field is BADTIME, in which case it will be a 48-bit
///      unsigned integer containing the server's current time as the
///      number of seconds since 00:00 on 1970-01-01 UTC, ignoring leap
///      seconds (see Section 5.2.3).  This document assigns no meaning to
///      its contents in requests.
/// ```
@available(macOS 9999, *)
public struct TSIG {
    /// Algorithm used to authenticate communication
    ///
    /// [RFC8945 Secret Key Transaction Authentication for DNS](https://tools.ietf.org/html/rfc8945#section-6)
    /// ```text
    ///      +==========================+================+=================+
    ///      | Algorithm Name           | Implementation | Use             |
    ///      +==========================+================+=================+
    ///      | HMAC-MD5.SIG-ALG.REG.INT | MAY            | MUST NOT        |
    ///      +--------------------------+----------------+-----------------+
    ///      | gss-tsig                 | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha1                | MUST           | NOT RECOMMENDED |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha224              | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha256              | MUST           | RECOMMENDED     |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha256-128          | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha384              | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha384-192          | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha512              | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha512-256          | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    /// ```
    @available(macOS 9999, *)
    public enum Algorithm {
        /// HMAC-MD5.SIG-ALG.REG.INT (not supported for cryptographic operations)
        case HMAC_MD5
        /// gss-tsig (not supported for cryptographic operations)
        case GSS
        /// hmac-sha1 (not supported for cryptographic operations)
        case HMAC_SHA1
        /// hmac-sha224 (not supported for cryptographic operations)
        case HMAC_SHA224
        /// hmac-sha256
        case HMAC_SHA256
        /// hmac-sha256-128 (not supported for cryptographic operations)
        case HMAC_SHA256_128
        /// hmac-sha384
        case HMAC_SHA384
        /// hmac-sha384-192 (not supported for cryptographic operations)
        case HMAC_SHA384_192
        /// hmac-sha512
        case HMAC_SHA512
        /// hmac-sha512-256 (not supported for cryptographic operations)
        case HMAC_SHA512_256
        /// Unknown algorithm
        case unknown(Name)
    }

    public let algorithm: Algorithm
    public let time: UInt64
    public let fudge: UInt16
    public let mac: [UInt8]
    public let oid: UInt16
    public let error: UInt16
    public let other: [UInt8]
}

@available(macOS 9999, *)
extension TSIG.Algorithm {
    public func toName() -> Name {
        switch self {
        case .HMAC_MD5: return .fromASCII("HMAC-MD5.SIG-ALG.REG.INT")
        case .GSS: return .fromASCII("gss-tsig")
        case .HMAC_SHA1: return .fromASCII("hmac-sha1")
        case .HMAC_SHA224: return .fromASCII("hmac-sha224")
        case .HMAC_SHA256: return .fromASCII("hmac-sha256")
        case .HMAC_SHA256_128: return .fromASCII("hmac-sha256-128")
        case .HMAC_SHA384: return .fromASCII("hmac-sha384")
        case .HMAC_SHA384_192: return .fromASCII("hmac-sha384-192")
        case .HMAC_SHA512: return .fromASCII("hmac-sha512")
        case .HMAC_SHA512_256: return .fromASCII("hmac-sha512-256")
        case .unknown(let name): return name
        }
    }
}
