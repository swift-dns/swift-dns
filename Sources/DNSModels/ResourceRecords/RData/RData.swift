@available(swiftDNSApplePlatforms 10.15, *)
public enum RData: Sendable {
    /// ```text
    /// -- RFC 1035 -- Domain Implementation and Specification    November 1987
    ///
    /// 3.4. Internet specific RRs
    ///
    /// 3.4.1. A RDATA format
    ///
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                    ADDRESS                    |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// where:
    ///
    /// ADDRESS         A 32 bit Internet address.
    ///
    /// Hosts that have multiple Internet addresses will have multiple A
    /// records.
    ///
    /// A records cause no additional section processing.  The RDATA section of
    /// an A line in a Zone File is an Internet address expressed as four
    /// decimal numbers separated by dots without any embedded spaces (e.g.,
    /// "10.2.0.52" or "192.0.5.6").
    /// ```
    case A(A)

    /// ```text
    /// -- RFC 1886 -- IPv6 DNS Extensions              December 1995
    ///
    /// 2.2 AAAA data format
    ///
    ///    A 128 bit IPv6 address is encoded in the data portion of an AAAA
    ///    resource record in network byte order (high-order byte first).
    /// ```
    case AAAA(AAAA)

    /// ```text
    /// -- RFC 6844          Certification Authority Authorization     January 2013
    ///
    /// 5.1.  Syntax
    ///
    /// A CAA RR contains a single property entry consisting of a tag-value
    /// pair.  Each tag represents a property of the CAA record.  The value
    /// of a CAA property is that specified in the corresponding value field.
    ///
    /// A domain name MAY have multiple CAA RRs associated with it and a
    /// given property MAY be specified more than once.
    ///
    /// The CAA data field contains one property entry.  A property entry
    /// consists of the following data fields:
    ///
    /// +0-1-2-3-4-5-6-7-|0-1-2-3-4-5-6-7-|
    /// | Flags          | Tag Length = n |
    /// +----------------+----------------+...+---------------+
    /// | Tag char 0     | Tag char 1     |...| Tag char n-1  |
    /// +----------------+----------------+...+---------------+
    /// +----------------+----------------+.....+----------------+
    /// | Value byte 0   | Value byte 1   |.....| Value byte m-1 |
    /// +----------------+----------------+.....+----------------+
    ///
    /// Where n is the length specified in the Tag length field and m is the
    /// remaining octets in the Value field (m = d - n - 2) where d is the
    /// length of the RDATA section.
    /// ```
    case CAA(CAA)

    /// ```text
    /// -- RFC 4398 -- Storing Certificates in DNS       November 1987
    /// The CERT resource record (RR) has the structure given below.  Its RR
    /// type code is 37.
    ///
    ///    1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    /// 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    /// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /// |             type              |             key tag           |
    /// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /// |   algorithm   |                                               /
    /// +---------------+            certificate or CRL                 /
    /// /                                                               /
    /// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
    //// ```
    case CERT(CERT)

    /// ```text
    ///   3.3. Standard RRs
    ///
    /// The following RR definitions are expected to occur, at least
    /// potentially, in all classes.  In particular, NS, SOA, CNAME, and PTR
    /// will be used in all classes, and have the same format in all classes.
    /// Because their RDATA format is known, all domain names in the RDATA
    /// section of these RRs may be compressed.
    ///
    /// <domain-name> is a domain name represented as a series of labels, and
    /// terminated by a label with zero length.  <character-string> is a single
    /// length octet followed by that number of characters.  <character-string>
    /// is treated as binary information, and can be up to 256 characters in
    /// length (including the length octet).
    ///
    /// 3.3.1. CNAME RDATA format
    ///
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     /                     CNAME                     /
    ///     /                                               /
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// where:
    ///
    /// CNAME           A <domain-name> which specifies the canonical or primary
    ///                 name for the owner.  The owner name is an alias.
    ///
    /// CNAME RRs cause no additional section processing, but name servers may
    /// choose to restart the query at the canonical name in certain cases.  See
    /// the description of name server logic in [RFC-1034] for details.
    /// ```
    case CNAME(CNAME)

    /// ```text
    /// 2.1.  The CSYNC Resource Record Format
    ///
    /// 2.1.1.  The CSYNC Resource Record Wire Format
    ///
    /// The CSYNC RDATA consists of the following fields:
    ///
    ///                     1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    /// 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    /// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /// |                          SOA Serial                           |
    /// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /// |       Flags                   |            Type Bit Map       /
    /// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /// /                     Type Bit Map (continued)                  /
    /// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /// ```
    case CSYNC(CSYNC)

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
    /// `HINFO` is also used by [RFC 8482](https://tools.ietf.org/html/rfc8482)
    case HINFO(HINFO)

    /// [RFC 9460, SVCB and HTTPS RRs](https://datatracker.ietf.org/doc/html/rfc9460#section-9)
    ///
    /// ```text
    /// 9.  Using Service Bindings with HTTP
    ///
    ///    The use of any protocol with SVCB requires a protocol-specific
    ///    mapping specification.  This section specifies the mapping for the
    ///    "http" and "https" URI schemes [HTTP].
    ///
    ///    To enable special handling for HTTP use cases, the HTTPS RR type is
    ///    defined as a SVCB-compatible RR type, specific to the "https" and
    ///    "http" schemes.  Clients MUST NOT perform SVCB queries or accept SVCB
    ///    responses for "https" or "http" schemes.
    ///
    ///    The presentation format of the record is:
    ///
    ///    DomainName TTL IN HTTPS SvcPriority TargetName SvcParams
    /// ```
    case HTTPS(HTTPS)

    /// ```text
    /// 3.3.9. MX RDATA format
    ///
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                  PREFERENCE                   |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     /                   EXCHANGE                    /
    ///     /                                               /
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// where:
    ///
    /// PREFERENCE      A 16 bit integer which specifies the preference given to
    ///                 this RR among others at the same owner.  Lower values
    ///                 are preferred.
    ///
    /// EXCHANGE        A <domain-name> which specifies a host willing to act as
    ///                 a mail exchange for the owner name.
    ///
    /// MX records cause type A additional section processing for the host
    /// specified by EXCHANGE.  The use of MX RRs is explained in detail in
    /// [RFC-974].
    /// ```
    case MX(MX)

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
    ///
    ///   ORDER
    ///      A 16-bit unsigned integer specifying the order in which the NAPTR
    ///      records MUST be processed in order to accurately represent the
    ///      ordered list of Rules.  The ordering is from lowest to highest.
    ///      If two records have the same order value then they are considered
    ///      to be the same rule and should be selected based on the
    ///      combination of the Preference values and Services offered.
    ///
    ///   PREFERENCE
    ///      Although it is called "preference" in deference to DNS
    ///      terminology, this field is equivalent to the Priority value in the
    ///      DDDS Algorithm.  It is a 16-bit unsigned integer that specifies
    ///      the order in which NAPTR records with equal Order values SHOULD be
    ///      processed, low numbers being processed before high numbers.  This
    ///      is similar to the preference field in an MX record, and is used so
    ///      domain administrators can direct clients towards more capable
    ///      hosts or lighter weight protocols.  A client MAY look at records
    ///      with higher preference values if it has a good reason to do so
    ///      such as not supporting some protocol or service very well.
    ///
    ///      The important difference between Order and Preference is that once
    ///      a match is found the client MUST NOT consider records with a
    ///      different Order but they MAY process records with the same Order
    ///      but different Preferences.  The only exception to this is noted in
    ///      the second important Note in the DDDS algorithm specification
    ///      concerning allowing clients to use more complex Service
    ///      determination between steps 3 and 4 in the algorithm.  Preference
    ///      is used to give communicate a higher quality of service to rules
    ///      that are considered the same from an authority standpoint but not
    ///      from a simple load balancing standpoint.
    ///
    ///      It is important to note that DNS contains several load balancing
    ///      mechanisms and if load balancing among otherwise equal services
    ///      should be needed then methods such as SRV records or multiple A
    ///      records should be utilized to accomplish load balancing.
    ///
    ///   FLAGS
    ///      A <character-string> containing flags to control aspects of the
    ///      rewriting and interpretation of the fields in the record.  Flags
    ///      are single characters from the set A-Z and 0-9.  The case of the
    ///      alphabetic characters is not significant.  The field can be empty.
    ///
    ///      It is up to the Application specifying how it is using this
    ///      Database to define the Flags in this field.  It must define which
    ///      ones are terminal and which ones are not.
    ///
    ///   SERVICES
    ///      A <character-string> that specifies the Service Parameters
    ///      applicable to this this delegation path.  It is up to the
    ///      Application Specification to specify the values found in this
    ///      field.
    ///
    ///   REGEXP
    ///      A <character-string> containing a substitution expression that is
    ///      applied to the original string held by the client in order to
    ///      construct the next domain name to lookup.  See the DDDS Algorithm
    ///      specification for the syntax of this field.
    ///
    ///      As stated in the DDDS algorithm, The regular expressions MUST NOT
    ///      be used in a cumulative fashion, that is, they should only be
    ///      applied to the original string held by the client, never to the
    ///      domain name produced by a previous NAPTR rewrite.  The latter is
    ///      tempting in some applications but experience has shown such use to
    ///      be extremely fault sensitive, very error prone, and extremely
    ///      difficult to debug.
    ///
    ///   REPLACEMENT
    ///      A <domain-name> which is the next domain-name to query for
    ///      depending on the potential values found in the flags field.  This
    ///      field is used when the regular expression is a simple replacement
    ///      operation.  Any value in this field MUST be a fully qualified
    ///      domain-name.  DomainName compression is not to be used for this field.
    ///
    ///      This field and the REGEXP field together make up the Substitution
    ///      Expression in the DDDS Algorithm.  It is simply a historical
    ///      optimization specifically for DNS compression that this field
    ///      exists.  The fields are also mutually exclusive.  If a record is
    ///      returned that has values for both fields then it is considered to
    ///      be in error and SHOULD be either ignored or an error returned.
    /// ```
    case NAPTR(NAPTR)

    /// ```text
    /// 3.3.10. NULL RDATA format (EXPERIMENTAL)
    ///
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     /                  <anything>                   /
    ///     /                                               /
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// Anything at all may be in the RDATA field so long as it is 65535 octets
    /// or less.
    ///
    /// NULL records cause no additional section processing.  NULL RRs are not
    /// allowed in Zone Files.  NULLs are used as placeholders in some
    /// experimental extensions of the DNS.
    /// ```
    case NULL(NULL)

    /// ```text
    /// 3.3.11. NS RDATA format
    ///
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     /                   NSDNAME                     /
    ///     /                                               /
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// where:
    ///
    /// NSDNAME         A <domain-name> which specifies a host which should be
    ///                 authoritative for the specified class and domain.
    ///
    /// NS records cause both the usual additional section processing to locate
    /// a type A record, and, when used in a referral, a special search of the
    /// zone in which they reside for glue information.
    ///
    /// The NS RR states that the named host should be expected to have a zone
    /// starting at owner name of the specified class.  Note that the class may
    /// not indicate the protocol family which should be used to communicate
    /// with the host, although it is typically a strong hint.  For example,
    /// hosts which are name servers for either Internet (IN) or Hesiod (HS)
    /// class information are normally queried using IN class protocols.
    /// ```
    case NS(NS)

    /// [RFC 7929](https://tools.ietf.org/html/rfc7929#section-2.1)
    ///
    /// ```text
    /// The RDATA portion of an OPENPGPKEY resource record contains a single
    /// value consisting of a Transferable Public Key formatted as specified
    /// in [RFC4880].
    /// ```
    case OPENPGPKEY(OPENPGPKEY)

    /// ```text
    /// RFC 6891                   EDNS(0) Extensions                 April 2013
    /// 6.1.2.  Wire Format
    ///
    ///        +------------+--------------+------------------------------+
    ///        | Field DomainName | Field Type   | Description                  |
    ///        +------------+--------------+------------------------------+
    ///        | NAME       | domain name  | MUST be 0 (root domain)      |
    ///        | TYPE       | u_int16_t    | OPT (41)                     |
    ///        | CLASS      | u_int16_t    | requestor's UDP payload size |
    ///        | TTL        | u_int32_t    | extended RCODE and flags     |
    ///        | RDLEN      | u_int16_t    | length of all RDATA          |
    ///        | RDATA      | octet stream | {attribute,value} pairs      |
    ///        +------------+--------------+------------------------------+
    ///
    /// The variable part of an OPT RR may contain zero or more options in
    /// the RDATA.  Each option MUST be treated as a bit field.  Each option
    /// is encoded as:
    ///
    ///                   +0 (MSB)                            +1 (LSB)
    ///        +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    ///     0: |                          OPTION-CODE                          |
    ///        +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    ///     2: |                         OPTION-LENGTH                         |
    ///        +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    ///     4: |                                                               |
    ///        /                          OPTION-DATA                          /
    ///        /                                                               /
    ///        +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    /// ```
    case OPT(OPT)

    /// ```text
    /// 3.3.12. PTR RDATA format
    ///
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     /                   PTRDNAME                    /
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// where:
    ///
    /// PTRDNAME        A <domain-name> which points to some location in the
    ///                 domain name space.
    ///
    /// PTR records cause no additional section processing.  These RRs are used
    /// in special domains to point to some other location in the domain space.
    /// These records are simple data, and don't imply any special processing
    /// similar to that performed by CNAME, which identifies aliases.  See the
    /// description of the IN-ADDR.ARPA domain for an example.
    /// ```
    case PTR(PTR)

    /// ```text
    /// 3.3.13. SOA RDATA format
    ///
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     /                     MNAME                     /
    ///     /                                               /
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     /                     RNAME                     /
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                    SERIAL                     |
    ///     |                                               |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                    REFRESH                    |
    ///     |                                               |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                     RETRY                     |
    ///     |                                               |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                    EXPIRE                     |
    ///     |                                               |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                    MINIMUM                    |
    ///     |                                               |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// where:
    ///
    /// MNAME           The <domain-name> of the name server that was the
    ///                 original or primary source of data for this zone.
    ///
    /// RNAME           A <domain-name> which specifies the mailbox of the
    ///                 person responsible for this zone.
    ///
    /// SERIAL          The unsigned 32 bit version number of the original copy
    ///                 of the zone.  Zone transfers preserve this value.  This
    ///                 value wraps and should be compared using sequence space
    ///                 arithmetic.
    ///
    /// REFRESH         A 32 bit time interval before the zone should be
    ///                 refreshed.
    ///
    /// RETRY           A 32 bit time interval that should elapse before a
    ///                 failed refresh should be retried.
    ///
    /// EXPIRE          A 32 bit time value that specifies the upper limit on
    ///                 the time interval that can elapse before the zone is no
    ///                 longer authoritative.
    ///
    /// MINIMUM         The unsigned 32 bit minimum TTL field that should be
    ///                 exported with any RR from this zone.
    ///
    /// SOA records cause no additional section processing.
    ///
    /// All times are in units of seconds.
    ///
    /// Most of these fields are pertinent only for name server maintenance
    /// operations.  However, MINIMUM is used in all query operations that
    /// retrieve RRs from a zone.  Whenever a RR is sent in a response to a
    /// query, the TTL field is set to the maximum of the TTL field from the RR
    /// and the MINIMUM field in the appropriate SOA.  Thus MINIMUM is a lower
    /// bound on the TTL field for all RRs in a zone.  Note that this use of
    /// MINIMUM should occur when the RRs are copied into the response and not
    /// when the zone is loaded from a Zone File or via a zone transfer.  The
    /// reason for this provision is to allow future dynamic update facilities to
    /// change the SOA RR with known semantics.
    /// ```
    case SOA(SOA)

    /// ```text
    /// RFC 2782                       DNS SRV RR                  February 2000
    ///
    /// The format of the SRV RR
    ///
    ///  _Service._Proto.DomainName TTL Class SRV Priority Weight Port Target
    /// ```
    case SRV(SRV)

    /// [RFC 4255](https://tools.ietf.org/html/rfc4255#section-3.1)
    ///
    /// ```text
    /// 3.1.  The SSHFP RDATA Format
    ///
    ///    The RDATA for a SSHFP RR consists of an algorithm number, fingerprint
    ///    type and the fingerprint of the public host key.
    ///
    ///        1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///        |   algorithm   |    fp type    |                               /
    ///        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               /
    ///        /                                                               /
    ///        /                          fingerprint                          /
    ///        /                                                               /
    ///        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///
    /// 3.1.1.  Algorithm Number Specification
    ///
    ///    This algorithm number octet describes the algorithm of the public
    ///    key.  The following values are assigned:
    ///
    ///           Value    Algorithm name
    ///           -----    --------------
    ///           0        reserved
    ///           1        RSA
    ///           2        DSS
    ///
    ///    Reserving other types requires IETF consensus [4].
    ///
    /// 3.1.2.  Fingerprint Type Specification
    ///
    ///    The fingerprint type octet describes the message-digest algorithm
    ///    used to calculate the fingerprint of the public key.  The following
    ///    values are assigned:
    ///
    ///           Value    Fingerprint type
    ///           -----    ----------------
    ///           0        reserved
    ///           1        SHA-1
    ///
    ///    Reserving other types requires IETF consensus [4].
    ///
    ///    For interoperability reasons, as few fingerprint types as possible
    ///    should be reserved.  The only reason to reserve additional types is
    ///    to increase security.
    ///
    /// 3.1.3.  Fingerprint
    ///
    ///    The fingerprint is calculated over the public key blob as described
    ///    in [7].
    ///
    ///    The message-digest algorithm is presumed to produce an opaque octet
    ///    string output, which is placed as-is in the RDATA fingerprint field.
    /// ```
    ///
    /// The algorithm and fingerprint type values have been updated in
    /// [RFC 6594](https://tools.ietf.org/html/rfc6594) and
    /// [RFC 7479](https://tools.ietf.org/html/rfc7479).
    case SSHFP(SSHFP)

    /// [RFC 9460, SVCB and HTTPS RRs](https://datatracker.ietf.org/doc/html/rfc9460#section-2)
    ///
    /// ```text
    /// 2.  The SVCB Record Type
    ///
    ///    The SVCB DNS RR type (RR type 64) is used to locate alternative
    ///    endpoints for a service.
    ///
    ///    The algorithm for resolving SVCB records and associated address
    ///    records is specified in Section 3.
    ///
    ///    Other SVCB-compatible RR types can also be defined as needed (see
    ///    Section 6).  In particular, the HTTPS RR (RR type 65) provides
    ///    special handling for the case of "https" origins as described in
    ///    Section 9.
    ///
    ///    SVCB RRs are extensible by a list of SvcParams, which are pairs
    ///    consisting of a SvcParamKey and a SvcParamValue.  Each SvcParamKey
    ///    has a presentation name and a registered number.  Values are in a
    ///    format specific to the SvcParamKey.  Each SvcParam has a specified
    ///    presentation format (used in zone files) and wire encoding (e.g.,
    ///    domain names, binary data, or numeric values).  The initial
    ///    SvcParamKeys and their formats are defined in Section 7.
    /// ```
    case SVCB(SVCB)

    /// [RFC 6698, DNS-Based Authentication for TLS](https://tools.ietf.org/html/rfc6698#section-2.1)
    ///
    /// ```text
    ///                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |  Cert. Usage  |   Selector    | Matching Type |               /
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               /
    ///    /                                                               /
    ///    /                 Certificate Association Data                  /
    ///    /                                                               /
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /// ```
    case TLSA(TLSA)

    /// ```text
    /// 3.3.14. TXT RDATA format
    ///
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     /                   TXT-DATA                    /
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// where:
    ///
    /// TXT-DATA        One or more <character-string>s.
    ///
    /// TXT RRs are used to hold descriptive text.  The semantics of the text
    /// depends on the domain where it is found.
    /// ```
    case TXT(TXT)

    /// A DNSSEC- or SIG(0)- specific record. See `DNSSECRData` for details.
    ///
    /// These types are in `DNSSECRData` to make them easy to disable when
    /// crypto functionality isn't needed.
    case DNSSEC(DNSSECRData)

    /// Unknown RecordData is for record types that are not supported
    case unknown(
        /// RecordType code
        code: RecordType,
        /// RData associated to the record
        rdata: NULL
    )

    /// Update record with RDLENGTH = 0 (RFC2136)
    case Update0(RecordType)
}

@available(swiftDNSApplePlatforms 10.15, *)
extension RData {
    var recordType: RecordType {
        switch self {
        case .A: return .A
        case .AAAA: return .AAAA
        case .CAA: return .CAA
        case .CERT: return .CERT
        case .CNAME: return .CNAME
        case .CSYNC: return .CSYNC
        case .HINFO: return .HINFO
        case .HTTPS: return .HTTPS
        case .MX: return .MX
        case .NAPTR: return .NAPTR
        case .NS: return .NS
        case .NULL: return .NULL
        case .OPENPGPKEY: return .OPENPGPKEY
        case .OPT: return .OPT
        case .PTR: return .PTR
        case .SOA: return .SOA
        case .SRV: return .SRV
        case .SSHFP: return .SSHFP
        case .SVCB: return .SVCB
        case .TLSA: return .TLSA
        case .TXT: return .TXT
        case .DNSSEC(let data): return data.recordType
        case .unknown(let code, _): return code
        case .Update0(let recordType): return recordType
        }
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension RData {
    package init(from buffer: inout DNSBuffer, recordType: RecordType) throws {
        let length = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("RData.length", buffer)
        )
        /// `length` is a `UInt16`, so it's safe to convert to Int
        self = try buffer.withTruncatedReadableBytes(
            length: Int(length),
            orThrow: .failedToRead("RData.length", buffer)
        ) { buffer -> RData in
            /// FIXME: is this valid? :
            /// This is to handle updates, RFC 2136, which uses 0 to indicate certain aspects of
            /// pre-requisites Null represents any data.
            if buffer.readableBytes == 0 {
                return .Update0(recordType)
            }
            switch recordType {
            case .A:
                return .A(try DNSModels.A(from: &buffer))
            case .AAAA:
                return .AAAA(try DNSModels.AAAA(from: &buffer))
            case .ANY:
                fatalError("RData.ANY not implemented")
            case .AXFR:
                fatalError("RData.AXFR not implemented")
            case .CAA:
                return .CAA(try DNSModels.CAA(from: &buffer))
            case .CDS:
                return .DNSSEC(DNSSECRData.CDS(try DNSModels.CDS(from: &buffer)))
            case .CDNSKEY:
                return .DNSSEC(DNSSECRData.CDNSKEY(try DNSModels.CDNSKEY(from: &buffer)))
            case .CERT:
                return .CERT(try DNSModels.CERT(from: &buffer))
            case .CNAME:
                return .CNAME(try DNSModels.CNAME(from: &buffer))
            case .CSYNC:
                return .CSYNC(try DNSModels.CSYNC(from: &buffer))
            case .DNSKEY:
                return .DNSSEC(DNSSECRData.DNSKEY(try DNSModels.DNSKEY(from: &buffer)))
            case .DS:
                return .DNSSEC(DNSSECRData.DS(try DNSModels.DS(from: &buffer)))
            case .HINFO:
                return .HINFO(try DNSModels.HINFO(from: &buffer))
            case .HTTPS:
                return .HTTPS(try DNSModels.HTTPS(from: &buffer))
            case .IXFR:
                fatalError("RData.IXFR not implemented")
            case .KEY:
                return .DNSSEC(DNSSECRData.KEY(try DNSModels.KEY(from: &buffer)))
            case .MX:
                return .MX(try DNSModels.MX(from: &buffer))
            case .NAPTR:
                return .NAPTR(try DNSModels.NAPTR(from: &buffer))
            case .NS:
                return .NS(try DNSModels.NS(from: &buffer))
            case .NSEC:
                return .DNSSEC(DNSSECRData.NSEC(try DNSModels.NSEC(from: &buffer)))
            case .NSEC3:
                return .DNSSEC(DNSSECRData.NSEC3(try DNSModels.NSEC3(from: &buffer)))
            case .NSEC3PARAM:
                return .DNSSEC(DNSSECRData.NSEC3PARAM(try DNSModels.NSEC3PARAM(from: &buffer)))
            case .NULL:
                return .NULL(try DNSModels.NULL(from: &buffer))
            case .OPENPGPKEY:
                return .OPENPGPKEY(try DNSModels.OPENPGPKEY(from: &buffer))
            case .OPT:
                return .OPT(try DNSModels.OPT(from: &buffer))
            case .PTR:
                return .PTR(try DNSModels.PTR(from: &buffer))
            case .RRSIG:
                return .DNSSEC(DNSSECRData.RRSIG(try DNSModels.RRSIG(from: &buffer)))
            case .SIG:
                return .DNSSEC(DNSSECRData.SIG(try DNSModels.SIG(from: &buffer)))
            case .SOA:
                return .SOA(try DNSModels.SOA(from: &buffer))
            case .SRV:
                return .SRV(try DNSModels.SRV(from: &buffer))
            case .SSHFP:
                return .SSHFP(try DNSModels.SSHFP(from: &buffer))
            case .SVCB:
                return .SVCB(try DNSModels.SVCB(from: &buffer))
            case .TLSA:
                return .TLSA(try DNSModels.TLSA(from: &buffer))
            case .TSIG:
                return .DNSSEC(DNSSECRData.TSIG(try DNSModels.TSIG(from: &buffer)))
            case .TXT:
                return .TXT(try DNSModels.TXT(from: &buffer))
            case .unknown:
                let null = try DNSModels.NULL(from: &buffer)
                return .unknown(code: recordType, rdata: null)
            }

            assert(
                buffer.readableBytes == 0,
                "RData.init(from:...) did not consume the entire buffer?: \(buffer)"
            )
        }
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension RData {
    package func encode(into buffer: inout DNSBuffer) throws {
        var valueBuffer = DNSBuffer()

        switch self {
        case .A(let a):
            a.encode(into: &valueBuffer)
        case .AAAA(let aaaa):
            aaaa.encode(into: &valueBuffer)
        case .CAA(let caa):
            try caa.encode(into: &valueBuffer)
        case .CERT(let cert):
            try cert.encode(into: &valueBuffer)
        case .CNAME(let cname):
            try cname.encode(into: &valueBuffer)
        case .CSYNC(let csync):
            try csync.encode(into: &valueBuffer)
        case .HINFO(let hinfo):
            try hinfo.encode(into: &valueBuffer)
        case .HTTPS(let https):
            try https.encode(into: &valueBuffer)
        case .MX(let mx):
            try mx.encode(into: &valueBuffer)
        case .NAPTR(let naptr):
            try naptr.encode(into: &valueBuffer)
        case .NS(let ns):
            try ns.encode(into: &valueBuffer)
        case .NULL(let null):
            try null.encode(into: &valueBuffer)
        case .OPENPGPKEY(let openpgpkey):
            try openpgpkey.encode(into: &valueBuffer)
        case .OPT(let opt):
            try opt.encode(into: &valueBuffer)
        case .PTR(let ptr):
            try ptr.encode(into: &valueBuffer)
        case .SOA(let soa):
            try soa.encode(into: &valueBuffer)
        case .SRV(let srv):
            try srv.encode(into: &valueBuffer)
        case .SSHFP(let sshfp):
            try sshfp.encode(into: &valueBuffer)
        case .SVCB(let svcb):
            try svcb.encode(into: &valueBuffer)
        case .TLSA(let tlsa):
            try tlsa.encode(into: &valueBuffer)
        case .TXT(let txt):
            try txt.encode(into: &valueBuffer)
        case .DNSSEC(let dnssec):
            try dnssec.encode(into: &valueBuffer)
        case .unknown(_, let rdata):
            try rdata.encode(into: &valueBuffer)
        case .Update0:
            /// Nothing to encode
            break
        }

        /// FIXME: check no overflow?
        /// FIXME: use "writeLengthPrefixed"
        buffer.writeInteger(UInt16(valueBuffer.readableBytes))
        buffer.writeBuffer(&valueBuffer)
    }
}
