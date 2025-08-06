public import struct NIOCore.ByteBuffer

///  [RFC 9460 SVCB and HTTPS Resource Records, Nov 2023](https://datatracker.ietf.org/doc/html/rfc9460#section-2.2)
///
/// ```text
/// 2.2.  RDATA wire format
///
///   The RDATA for the SVCB RR consists of:
///
///   *  a 2 octet field for SvcPriority as an integer in network byte
///      order.
///   *  the uncompressed, fully-qualified TargetName, represented as a
///      sequence of length-prefixed labels as in Section 3.1 of [RFC1035].
///   *  the SvcParams, consuming the remainder of the record (so smaller
///      than 65535 octets and constrained by the RDATA and DNS message
///      sizes).
///
///   When the list of SvcParams is non-empty (ServiceMode), it contains a
///   series of SvcParamKey=SvcParamValue pairs, represented as:
///
///   *  a 2 octet field containing the SvcParamKey as an integer in
///      network byte order.  (See Section 14.3.2 for the defined values.)
///   *  a 2 octet field containing the length of the SvcParamValue as an
///      integer between 0 and 65535 in network byte order
///   *  an octet string of this length whose contents are the SvcParamValue
///      in a format determined by the SvcParamKey
///
///   SvcParamKeys SHALL appear in increasing numeric order.
///
///   Clients MUST consider an RR malformed if:
///
///   *  the end of the RDATA occurs within a SvcParam.
///   *  SvcParamKeys are not in strictly increasing numeric order.
///   *  the SvcParamValue for an SvcParamKey does not have the expected
///      format.
///
///   Note that the second condition implies that there are no duplicate
///   SvcParamKeys.
///
///   If any RRs are malformed, the client MUST reject the entire RRSet and
///   fall back to non-SVCB connection establishment.
/// ```
@available(swiftDNSApplePlatforms 26, *)
public struct SVCB: Sendable {
    ///  [RFC 9460 SVCB and HTTPS Resource Records, Nov 2023](https://datatracker.ietf.org/doc/html/rfc9460#section-14.3.2)
    ///
    /// ```text
    /// 14.3.2.  Initial Contents
    ///
    ///    The "Service Parameter Keys (SvcParamKeys)" registry has been
    ///    populated with the following initial registrations:
    ///
    ///    +===========+=================+================+=========+==========+
    ///    |   Number  | Name            | Meaning        |Reference|Change    |
    ///    |           |                 |                |         |Controller|
    ///    +===========+=================+================+=========+==========+
    ///    |     0     | mandatory       | Mandatory      |RFC 9460,|IETF      |
    ///    |           |                 | keys in this   |Section 8|          |
    ///    |           |                 | RR             |         |          |
    ///    +-----------+-----------------+----------------+---------+----------+
    ///    |     1     | alpn            | Additional     |RFC 9460,|IETF      |
    ///    |           |                 | supported      |Section  |          |
    ///    |           |                 | protocols      |7.1      |          |
    ///    +-----------+-----------------+----------------+---------+----------+
    ///    |     2     | no-default-alpn | No support     |RFC 9460,|IETF      |
    ///    |           |                 | for default    |Section  |          |
    ///    |           |                 | protocol       |7.1      |          |
    ///    +-----------+-----------------+----------------+---------+----------+
    ///    |     3     | port            | Port for       |RFC 9460,|IETF      |
    ///    |           |                 | alternative    |Section  |          |
    ///    |           |                 | endpoint       |7.2      |          |
    ///    +-----------+-----------------+----------------+---------+----------+
    ///    |     4     | ipv4hint        | IPv4 address   |RFC 9460,|IETF      |
    ///    |           |                 | hints          |Section  |          |
    ///    |           |                 |                |7.3      |          |
    ///    +-----------+-----------------+----------------+---------+----------+
    ///    |     5     | ech             | RESERVED       |N/A      |IETF      |
    ///    |           |                 | (held for      |         |          |
    ///    |           |                 | Encrypted      |         |          |
    ///    |           |                 | ClientHello)   |         |          |
    ///    +-----------+-----------------+----------------+---------+----------+
    ///    |     6     | ipv6hint        | IPv6 address   |RFC 9460,|IETF      |
    ///    |           |                 | hints          |Section  |          |
    ///    |           |                 |                |7.3      |          |
    ///    +-----------+-----------------+----------------+---------+----------+
    ///    |65280-65534| N/A             | Reserved for   |RFC 9460 |IETF      |
    ///    |           |                 | Private Use    |         |          |
    ///    +-----------+-----------------+----------------+---------+----------+
    ///    |   65535   | N/A             | Reserved       |RFC 9460 |IETF      |
    ///    |           |                 | ("Invalid      |         |          |
    ///    |           |                 | key")          |         |          |
    ///    +-----------+-----------------+----------------+---------+----------+
    ///
    /// parsing done via:
    ///   *  a 2 octet field containing the SvcParamKey as an integer in
    ///      network byte order.  (See Section 14.3.2 for the defined values.)
    /// ```
    public enum SVCParamKey: Sendable {
        /// Mandatory keys in this RR
        case mandatory
        /// Additional supported protocols
        case alpn
        /// No support for default protocol
        case noDefaultALPN
        /// Port for alternative endpoint
        case port
        /// IPv4 address hints
        case ipv4hint
        /// Encrypted Client Hello configuration list
        case echConfigList
        /// IPv6 address hints
        case ipv6hint
        /// Private Use
        case key(UInt16)
        /// Reserved ("Invalid key")
        case key65535
        /// Unknown
        case unknown(UInt16)
    }

    /// Warning, it is currently up to users of this type to validate the data against that expected by the key
    ///
    /// ```text
    ///   *  a 2 octet field containing the length of the SvcParamValue as an
    ///      integer between 0 and 65535 in network byte order (but constrained
    ///      by the RDATA and DNS message sizes).
    ///   *  an octet string of this length whose contents are in a format
    ///      determined by the SvcParamKey.
    /// ```
    @available(swiftDNSApplePlatforms 26, *)
    public enum SVCParamValue: Sendable {
        ///  [RFC 9460 SVCB and HTTPS Resource Records, Nov 2023](https://datatracker.ietf.org/doc/html/rfc9460#section-8)
        ///
        /// ```text
        /// 8.  ServiceMode RR compatibility and mandatory keys
        ///
        ///    In a ServiceMode RR, a SvcParamKey is considered "mandatory" if the
        ///    RR will not function correctly for clients that ignore this
        ///    SvcParamKey.  Each SVCB protocol mapping SHOULD specify a set of keys
        ///    that are "automatically mandatory", i.e. mandatory if they are
        ///    present in an RR.  The SvcParamKey "mandatory" is used to indicate
        ///    any mandatory keys for this RR, in addition to any automatically
        ///    mandatory keys that are present.
        ///
        ///    A ServiceMode RR is considered "compatible" with a client if the
        ///    client recognizes all the mandatory keys, and their values indicate
        ///    that successful connection establishment is possible. Incompatible RRs
        ///    are ignored (see step 5 of the procedure defined in Section 3)
        ///
        ///    The presentation value SHALL be a comma-separated list
        ///    (Appendix A.1) of one or more valid SvcParamKeys, either by their
        ///    registered name or in the unknown-key format (Section 2.1).  Keys MAY
        ///    appear in any order, but MUST NOT appear more than once.  For self-
        ///    consistency (Section 2.4.3), listed keys MUST also appear in the
        ///    SvcParams.
        ///
        ///    To enable simpler parsing, this SvcParamValue MUST NOT contain escape
        ///    sequences.
        ///
        ///    For example, the following is a valid list of SvcParams:
        ///
        ///    ipv6hint=... key65333=ex1 key65444=ex2 mandatory=key65444,ipv6hint
        ///
        ///    In wire format, the keys are represented by their numeric values in
        ///    network byte order, concatenated in strictly increasing numeric order.
        ///
        ///    This SvcParamKey is always automatically mandatory, and MUST NOT
        ///    appear in its own value-list.  Other automatically mandatory keys
        ///    SHOULD NOT appear in the list either.  (Including them wastes space
        ///    and otherwise has no effect.)
        /// ```
        public struct Mandatory: Sendable {
            public var keys: [SVCParamKey]

            public init(keys: [SVCParamKey]) {
                self.keys = keys
            }
        }

        ///  [RFC 9460 SVCB and HTTPS Resource Records, Nov 2023](https://datatracker.ietf.org/doc/html/rfc9460#section-7.1)
        ///
        /// ```text
        /// 7.1.  "alpn" and "no-default-alpn"
        ///
        ///   The "alpn" and "no-default-alpn" SvcParamKeys together indicate the
        ///   set of Application-Layer Protocol Negotiation (ALPN) protocol
        ///   identifiers [ALPN] and associated transport protocols supported by
        ///   this service endpoint (the "SVCB ALPN set").
        ///
        ///   As with Alt-Svc [AltSvc], each ALPN protocol identifier is used to
        ///   identify the application protocol and associated suite of protocols
        ///   supported by the endpoint (the "protocol suite").  The presence of an
        ///   ALPN protocol identifier in the SVCB ALPN set indicates that this
        ///   service endpoint, described by TargetName and the other parameters
        ///   (e.g., "port"), offers service with the protocol suite associated
        ///   with this ALPN identifier.
        ///
        ///   Clients filter the set of ALPN identifiers to match the protocol
        ///   suites they support, and this informs the underlying transport
        ///   protocol used (such as QUIC over UDP or TLS over TCP).  ALPN protocol
        ///   identifiers that do not uniquely identify a protocol suite (e.g., an
        ///   Identification Sequence that can be used with both TLS and DTLS) are
        ///   not compatible with this SvcParamKey and MUST NOT be included in the
        ///   SVCB ALPN set.
        ///
        /// 7.1.1.  Representation
        ///
        ///   ALPNs are identified by their registered "Identification Sequence"
        ///   (alpn-id), which is a sequence of 1-255 octets.
        ///
        ///   alpn-id = 1*255OCTET
        ///
        ///   For "alpn", the presentation value SHALL be a comma-separated list
        ///   (Appendix A.1) of one or more alpn-ids.  Zone-file implementations
        ///   MAY disallow the "," and "\" characters in ALPN IDs instead of
        ///   implementing the value-list escaping procedure, relying on the opaque
        ///   key format (e.g., key1=\002h2) in the event that these characters are
        ///   needed.
        ///
        ///   The wire-format value for "alpn" consists of at least one alpn-id
        ///   prefixed by its length as a single octet, and these length-value
        ///   pairs are concatenated to form the SvcParamValue.  These pairs MUST
        ///   exactly fill the SvcParamValue; otherwise, the SvcParamValue is
        ///   malformed.
        ///
        ///   For "no-default-alpn", the presentation and wire-format values MUST
        ///   be empty.  When "no-default-alpn" is specified in an RR, "alpn" must
        ///   also be specified in order for the RR to be "self-consistent"
        ///   (Section 2.4.3).
        ///
        ///   Each scheme that uses this SvcParamKey defines a "default set" of
        ///   ALPN IDs that are supported by nearly all clients and servers; this
        ///   set MAY be empty.  To determine the SVCB ALPN set, the client starts
        ///   with the list of alpn-ids from the "alpn" SvcParamKey, and it adds
        ///   the default set unless the "no-default-alpn" SvcParamKey is present.
        ///
        /// 7.1.2.  Use
        ///
        ///   To establish a connection to the endpoint, clients MUST
        ///
        ///   1.  Let SVCB-ALPN-Intersection be the set of protocols in the SVCB
        ///       ALPN set that the client supports.
        ///
        ///   2.  Let Intersection-Transports be the set of transports (e.g., TLS,
        ///       DTLS, QUIC) implied by the protocols in SVCB-ALPN-Intersection.
        ///
        ///   3.  For each transport in Intersection-Transports, construct a
        ///       ProtocolNameList containing the Identification Sequences of all
        ///       the client's supported ALPN protocols for that transport, without
        ///       regard to the SVCB ALPN set.
        ///
        ///   For example, if the SVCB ALPN set is ["http/1.1", "h3"] and the
        ///   client supports HTTP/1.1, HTTP/2, and HTTP/3, the client could
        ///   attempt to connect using TLS over TCP with a ProtocolNameList of
        ///   ["http/1.1", "h2"] and could also attempt a connection using QUIC
        ///   with a ProtocolNameList of ["h3"].
        ///
        ///   Once the client has constructed a ClientHello, protocol negotiation
        ///   in that handshake proceeds as specified in [ALPN], without regard to
        ///   the SVCB ALPN set.
        ///
        ///   Clients MAY implement a fallback procedure, using a less-preferred
        ///   transport if more-preferred transports fail to connect.  This
        ///   fallback behavior is vulnerable to manipulation by a network attacker
        ///   who blocks the more-preferred transports, but it may be necessary for
        ///   compatibility with existing networks.
        ///
        ///   With this procedure in place, an attacker who can modify DNS and
        ///   network traffic can prevent a successful transport connection but
        ///   cannot otherwise interfere with ALPN protocol selection.  This
        ///   procedure also ensures that each ProtocolNameList includes at least
        ///   one protocol from the SVCB ALPN set.
        ///
        ///   Clients SHOULD NOT attempt connection to a service endpoint whose
        ///   SVCB ALPN set does not contain any supported protocols.
        ///
        ///   To ensure consistency of behavior, clients MAY reject the entire SVCB
        ///   RRset and fall back to basic connection establishment if all of the
        ///   compatible RRs indicate "no-default-alpn", even if connection could
        ///   have succeeded using a non-default ALPN protocol.
        ///
        ///   Zone operators SHOULD ensure that at least one RR in each RRset
        ///   supports the default transports.  This enables compatibility with the
        ///   greatest number of clients.
        /// ```
        public struct ALPN: Sendable {
            public var protocols: [String]

            var lengthInDNSWireProtocol: Int {
                self.protocols.reduce(into: 0) { $0 += $1.lengthInDNSWireProtocol }
            }

            public init(protocols: [String]) {
                self.protocols = protocols
            }
        }

        ///  [RFC 9460 SVCB and HTTPS Resource Records, Nov 2023](https://datatracker.ietf.org/doc/html/rfc9460#section-7.3)
        ///
        /// ```text
        ///    7.3.  "ipv4hint" and "ipv6hint"
        ///
        ///   The "ipv4hint" and "ipv6hint" keys convey IP addresses that clients
        ///   MAY use to reach the service.  If A and AAAA records for TargetName
        ///   are locally available, the client SHOULD ignore these hints.
        ///   Otherwise, clients SHOULD perform A and/or AAAA queries for
        ///   TargetName per Section 3, and clients SHOULD use the IP address in
        ///   those responses for future connections.  Clients MAY opt to terminate
        ///   any connections using the addresses in hints and instead switch to
        ///   the addresses in response to the TargetName query.  Failure to use A
        ///   and/or AAAA response addresses could negatively impact load balancing
        ///   or other geo-aware features and thereby degrade client performance.
        ///
        ///   The presentation value SHALL be a comma-separated list (Appendix A.1)
        ///   of one or more IP addresses of the appropriate family in standard
        ///   textual format [RFC5952] [RFC4001].  To enable simpler parsing, this
        ///   SvcParamValue MUST NOT contain escape sequences.
        ///
        ///   The wire format for each parameter is a sequence of IP addresses in
        ///   network byte order (for the respective address family).  Like an A or
        ///   AAAA RRset, the list of addresses represents an unordered collection,
        ///   and clients SHOULD pick addresses to use in a random order.  An empty
        ///   list of addresses is invalid.
        ///
        ///   When selecting between IPv4 and IPv6 addresses to use, clients may
        ///   use an approach such as Happy Eyeballs [HappyEyeballsV2].  When only
        ///   "ipv4hint" is present, NAT64 clients may synthesize IPv6 addresses as
        ///   specified in [RFC7050] or ignore the "ipv4hint" key and wait for AAAA
        ///   resolution (Section 3).  For best performance, server operators
        ///   SHOULD include an "ipv6hint" parameter whenever they include an
        ///   "ipv4hint" parameter.
        ///
        ///   These parameters are intended to minimize additional connection
        ///   latency when a recursive resolver is not compliant with the
        ///   requirements in Section 4 and SHOULD NOT be included if most clients
        ///   are using compliant recursive resolvers.  When TargetName is the
        ///   service name or the owner name (which can be written as "."), server
        ///   operators SHOULD NOT include these hints, because they are unlikely
        ///   to convey any performance benefit.
        /// ```
        public struct IPHint<IPType: Sendable>: Sendable {
            public var addresses: [IPType]

            public init(addresses: [IPType]) {
                self.addresses = addresses
            }
        }

        /// [draft-ietf-tls-svcb-ech-01 Bootstrapping TLS Encrypted ClientHello with DNS Service Bindings, Sep 2024](https://datatracker.ietf.org/doc/html/draft-ietf-tls-svcb-ech-01)
        ///
        /// ```text
        /// 2.  "SvcParam for ECH configuration"
        ///
        ///   The "ech" SvcParamKey is defined for conveying the ECH configuration
        ///   of an alternative endpoint. It is applicable to all TLS-based protocols
        ///   (including DTLS [RFC9147] and QUIC version 1 [RFC9001]) unless
        ///   otherwise specified.
        ///
        ///   In wire format, the value of the parameter is an ECHConfigList (Section 4 of draft-ietf-tls-esni-18),
        ///   including the redundant length prefix. In presentation format, the value is the ECHConfigList
        ///   in Base 64 Encoding (Section 4 of [RFC4648]). Base 64 is used here to simplify integration
        ///   with TLS server software. To enable simpler parsing, this SvcParam MUST NOT contain escape
        ///   sequences.
        /// ```
        public struct ECHConfigList: Sendable {
            public var config: ByteBuffer

            public init(config: ByteBuffer) {
                self.config = config
            }
        }

        ///  [RFC 9460 SVCB and HTTPS Resource Records, Nov 2023](https://datatracker.ietf.org/doc/html/rfc9460#section-2.1)
        ///
        /// ```text
        ///   Arbitrary keys can be represented using the unknown-key presentation
        ///   format "keyNNNNN" where NNNNN is the numeric value of the key type
        ///   without leading zeros. A SvcParam in this form SHALL be parsed as specified
        ///   above, and the decoded value SHALL be used as its wire-format encoding.
        ///
        ///   For some SvcParamKeys, the value corresponds to a list or set of
        ///   items.  Presentation formats for such keys SHOULD use a comma-
        ///   separated list (Appendix A.1).
        ///
        ///   SvcParams in presentation format MAY appear in any order, but keys
        ///   MUST NOT be repeated.
        /// ```
        public struct Unknown: Sendable {
            public var data: ByteBuffer

            public init(data: ByteBuffer) {
                self.data = data
            }
        }

        ///    In a ServiceMode RR, a SvcParamKey is considered "mandatory" if the
        ///    RR will not function correctly for clients that ignore this
        ///    SvcParamKey.  Each SVCB protocol mapping SHOULD specify a set of keys
        ///    that are "automatically mandatory", i.e. mandatory if they are
        ///    present in an RR.  The SvcParamKey "mandatory" is used to indicate
        ///    any mandatory keys for this RR, in addition to any automatically
        ///    mandatory keys that are present.
        ///
        /// see `Mandatory`
        case mandatory(Mandatory)
        ///  [RFC 9460 SVCB and HTTPS Resource Records, Nov 2023](https://datatracker.ietf.org/doc/html/rfc9460#section-7.1)
        ///
        /// ```text
        ///    The "alpn" and "no-default-alpn" SvcParamKeys together indicate the
        ///    set of Application Layer Protocol Negotiation (ALPN) protocol
        ///    identifiers [ALPN] and associated transport protocols supported by
        ///    this service endpoint (the "SVCB ALPN set").
        /// ```
        case alpn(ALPN)
        /// For "no-default-alpn", the presentation and wire format values MUST
        ///    be empty.
        /// See also `ALPN`
        case noDefaultALPN
        ///  [RFC 9460 SVCB and HTTPS Resource Records, Nov 2023](https://datatracker.ietf.org/doc/html/rfc9460#section-7.2)
        ///
        /// ```text
        ///    7.2.  "port"
        ///
        ///   The "port" SvcParamKey defines the TCP or UDP port that should be
        ///   used to reach this alternative endpoint.  If this key is not present,
        ///   clients SHALL use the authority endpoint's port number.
        ///
        ///   The presentation value of the SvcParamValue is a single decimal
        ///   integer between 0 and 65535 in ASCII.  Any other value (e.g. an
        ///   empty value) is a syntax error.  To enable simpler parsing, this
        ///   SvcParam MUST NOT contain escape sequences.
        ///
        ///   The wire format of the SvcParamValue is the corresponding 2 octet
        ///   numeric value in network byte order.
        ///
        ///   If a port-restricting firewall is in place between some client and
        ///   the service endpoint, changing the port number might cause that
        ///   client to lose access to the service, so operators should exercise
        ///   caution when using this SvcParamKey to specify a non-default port.
        /// ```
        case port(UInt16)
        ///  [RFC 9460 SVCB and HTTPS Resource Records, Nov 2023](https://datatracker.ietf.org/doc/html/rfc9460#section-7.2)
        ///
        ///   The "ipv4hint" and "ipv6hint" keys convey IP addresses that clients
        ///   MAY use to reach the service.  If A and AAAA records for TargetName
        ///   are locally available, the client SHOULD ignore these hints.
        ///   Otherwise, clients SHOULD perform A and/or AAAA queries for
        ///   TargetName as in Section 3, and clients SHOULD use the IP address in
        ///   those responses for future connections.  Clients MAY opt to terminate
        ///   any connections using the addresses in hints and instead switch to
        ///   the addresses in response to the TargetName query.  Failure to use A
        ///   and/or AAAA response addresses could negatively impact load balancing
        ///   or other geo-aware features and thereby degrade client performance.
        ///
        /// see `IPHint`
        case ipv4hint(IPHint<A>)
        /// [draft-ietf-tls-svcb-ech-01 Bootstrapping TLS Encrypted ClientHello with DNS Service Bindings, Sep 2024](https://datatracker.ietf.org/doc/html/draft-ietf-tls-svcb-ech-01)
        ///
        /// ```text
        /// 2.  "SvcParam for ECH configuration"
        ///
        ///   The "ech" SvcParamKey is defined for conveying the ECH configuration
        ///   of an alternative endpoint. It is applicable to all TLS-based protocols
        ///   (including DTLS [RFC9147] and QUIC version 1 [RFC9001]) unless otherwise
        ///   specified.
        /// ```
        case echConfigList(ECHConfigList)
        /// See `IPHint`
        case ipv6hint(IPHint<AAAA>)
        /// Unparsed network data. Refer to documents on the associated key value
        ///
        /// This will be left as is when read off the wire, and encoded in bas64
        ///    for presentation.
        case unknown(Unknown)
    }

    public var svcPriority: UInt16
    public var targetName: Name
    public var svcParams: [(SVCParamKey, SVCParamValue)]

    public init(svcPriority: UInt16, targetName: Name, svcParams: [(SVCParamKey, SVCParamValue)]) {
        self.svcPriority = svcPriority
        self.targetName = targetName
        self.svcParams = svcParams
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB {
    package init(from buffer: inout DNSBuffer) throws {
        self.svcPriority = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("SVCB.priority", buffer)
        )
        self.targetName = try Name(from: &buffer)
        self.svcParams = []
        var remaining = buffer.readableBytes
        while remaining >= 4 {
            defer {
                remaining = buffer.readableBytes
            }
            let key = try SVCParamKey(from: &buffer)
            let value = try SVCParamValue(from: &buffer, key: key)
            self.svcParams.append((key, value))
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeInteger(self.svcPriority)
        try self.targetName.encode(into: &buffer)
        for (key, value) in self.svcParams {
            try key.encode(into: &buffer)
            try value.encode(into: &buffer)
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamKey: RawRepresentable {
    public init(_ rawValue: UInt16) {
        switch rawValue {
        case 0: self = .mandatory
        case 1: self = .alpn
        case 2: self = .noDefaultALPN
        case 3: self = .port
        case 4: self = .ipv4hint
        case 5: self = .echConfigList
        case 6: self = .ipv6hint
        case 65280...65534: self = .key(rawValue)
        case 65535: self = .key65535
        default: self = .unknown(rawValue)
        }
    }

    public init?(rawValue: UInt16) {
        self.init(rawValue)
    }

    public var rawValue: UInt16 {
        switch self {
        case .mandatory: return 0
        case .alpn: return 1
        case .noDefaultALPN: return 2
        case .port: return 3
        case .ipv4hint: return 4
        case .echConfigList: return 5
        case .ipv6hint: return 6
        case .key(let value): return value
        case .key65535: return 65535
        case .unknown(let value): return value
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamKey {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("SVCB.ParamKey", buffer)
        )
        self.init(rawValue)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue {
    package init(from buffer: inout DNSBuffer, key: SVCB.SVCParamKey) throws {
        let length = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("SVCB.SVCParamValue.length", buffer)
        )
        /// `length` is a `UInt16`, so it's safe to convert to Int
        self = try buffer.withTruncatedReadableBytes(
            length: Int(length),
            orThrow: .failedToRead("SVCB.SVCParamValue.valueData", buffer)
        ) { valueSlice -> SVCB.SVCParamValue in
            switch key {
            case .mandatory:
                return .mandatory(try Mandatory(from: &valueSlice))
            case .alpn:
                return .alpn(try ALPN(from: &valueSlice))
            case .noDefaultALPN:
                guard length == 0 else {
                    throw ProtocolError.failedToRead("SVCB.SVCParamValue.noDefaultALPN", valueSlice)
                }
                return .noDefaultALPN
            case .port:
                let port = try valueSlice.readInteger(as: UInt16.self).unwrap(
                    or: .failedToRead("SVCB.SVCParamValue.port", valueSlice)
                )
                return .port(port)
            case .ipv4hint:
                return .ipv4hint(try IPHint<A>(from: &valueSlice))
            case .echConfigList:
                return .echConfigList(try ECHConfigList(from: &valueSlice))
            case .ipv6hint:
                return .ipv6hint(try IPHint<AAAA>(from: &valueSlice))
            case .key:
                return .unknown(try Unknown(from: &valueSlice))
            case .key65535:
                return .unknown(try Unknown(from: &valueSlice))
            case .unknown:
                return .unknown(try Unknown(from: &valueSlice))
            }
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.Mandatory {
    package init(from buffer: inout DNSBuffer) throws {
        self.keys = []
        while buffer.readableBytes != 0 {
            self.keys.append(try SVCB.SVCParamKey(from: &buffer))
        }
        if self.keys.isEmpty {
            throw ProtocolError.failedToRead("SVCB.SVCParamValue.Mandatory.keys", buffer)
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.ALPN {
    package init(from buffer: inout DNSBuffer) throws {
        self.protocols = []
        while buffer.readableBytes != 0 {
            self.protocols.append(
                try buffer.readLengthPrefixedStringAsString(
                    name: "SVCB.SVCParamValue.ALPN.protocols"
                )
            )
            if self.protocols.isEmpty {
                throw ProtocolError.failedToRead("SVCB.SVCParamValue.ALPN.protocols", buffer)
            }
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.IPHint where IPType == A {
    package init(from buffer: inout DNSBuffer) throws {
        self.addresses = []
        while buffer.readableBytes != 0 {
            self.addresses.append(try A(from: &buffer))
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.IPHint where IPType == AAAA {
    package init(from buffer: inout DNSBuffer) throws {
        self.addresses = []
        while buffer.readableBytes != 0 {
            self.addresses.append(try AAAA(from: &buffer))
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.ECHConfigList {
    package init(from buffer: inout DNSBuffer) throws {
        self.config = buffer.readToEnd()
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.Unknown {
    package init(from buffer: inout DNSBuffer) throws {
        self.data = buffer.readToEnd()
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamKey {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeInteger(self.rawValue)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue {
    package func encode(into buffer: inout DNSBuffer) throws {
        var valueBuffer = DNSBuffer()

        switch self {
        case .mandatory(let mandatory):
            try mandatory.encode(into: &valueBuffer)
        case .alpn(let alpn):
            try alpn.encode(into: &valueBuffer)
        case .noDefaultALPN:
            /// Nothing to write
            break
        case .port(let port):
            valueBuffer.writeInteger(port)
        case .ipv4hint(let ipv4hint):
            try ipv4hint.encode(into: &valueBuffer)
        case .echConfigList(let echConfigList):
            try echConfigList.encode(into: &valueBuffer)
        case .ipv6hint(let ipv6hint):
            try ipv6hint.encode(into: &valueBuffer)
        case .unknown(let unknown):
            try unknown.encode(into: &valueBuffer)
        }

        /// FIXME: check no overflow?
        /// FIXME: use "writeLengthPrefixed"
        buffer.writeInteger(UInt16(valueBuffer.readableBytes))
        buffer.writeBuffer(&valueBuffer)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.Mandatory {
    package func encode(into buffer: inout DNSBuffer) throws {
        for key in self.keys {
            try key.encode(into: &buffer)
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.ALPN {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.reserveCapacity(minimumWritableBytes: self.lengthInDNSWireProtocol)
        for proto in self.protocols {
            try buffer.writeLengthPrefixedString(
                name: "SVCB.SVCParamValue.ALPN.protocols",
                bytes: proto.utf8,
                maxLength: 255,
                fitLengthInto: UInt8.self
            )
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.IPHint where IPType == A {
    package func encode(into buffer: inout DNSBuffer) throws {
        guard let length = Int(exactly: self.addresses.count * IPv4Address.size) else {
            throw ProtocolError.failedToValidate("SVCB.SVCParamValue.IPHint<A>", buffer)
        }
        buffer.reserveCapacity(minimumWritableBytes: length)
        for address in self.addresses {
            address.encode(into: &buffer)
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.IPHint where IPType == AAAA {
    package func encode(into buffer: inout DNSBuffer) throws {
        guard let length = Int(exactly: self.addresses.count * IPv6Address.size) else {
            throw ProtocolError.failedToValidate("SVCB.SVCParamValue.IPHint<AAAA>", buffer)
        }
        buffer.reserveCapacity(minimumWritableBytes: length)
        for address in self.addresses {
            address.encode(into: &buffer)
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.ECHConfigList {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeBuffer(self.config)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB.SVCParamValue.Unknown {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeBuffer(self.data)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .SVCB(let svcb):
            self = svcb
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .SVCB(self)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SVCB: Queryable {
    @inlinable
    public static var recordType: RecordType { .SVCB }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
