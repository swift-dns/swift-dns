/// The OPT record type is used for ExtendedDNS records.
///
/// These allow for additional information to be associated with the DNS request that otherwise
/// would require changes to the DNS protocol.
///
/// Multiple options with the same code are allowed to appear in this record
///
/// [RFC 6891, EDNS(0) Extensions, April 2013](https://tools.ietf.org/html/rfc6891#section-6)
///
/// ```text
/// 6.1.  OPT Record Definition
///
/// 6.1.1.  Basic Elements
///
///    An OPT pseudo-RR (sometimes called a meta-RR) MAY be added to the
///    additional data section of a request.
///
///    The OPT RR has RR type 41.
///
///    If an OPT record is present in a received request, compliant
///    responders MUST include an OPT record in their respective responses.
///
///    An OPT record does not carry any DNS data.  It is used only to
///    contain control information pertaining to the question-and-answer
///    sequence of a specific transaction.  OPT RRs MUST NOT be cached,
///    forwarded, or stored in or loaded from Zone Files.
///
///    The OPT RR MAY be placed anywhere within the additional data section.
///    When an OPT RR is included within any DNS message, it MUST be the
///    only OPT RR in that message.  If a query message with more than one
///    OPT RR is received, a FORMERR (RCODE=1) MUST be returned.  The
///    placement flexibility for the OPT RR does not override the need for
///    the TSIG or SIG(0) RRs to be the last in the additional section
///    whenever they are present.
///
/// 6.1.2.  Wire Format
///
///    An OPT RR has a fixed part and a variable set of options expressed as
///    {attribute, value} pairs.  The fixed part holds some DNS metadata,
///    and also a small collection of basic extension elements that we
///    expect to be so popular that it would be a waste of wire space to
///    encode them as {attribute, value} pairs.
///
///    The fixed part of an OPT RR is structured as follows:
///
///        +------------+--------------+------------------------------+
///        | Field Name | Field Type   | Description                  |
///        +------------+--------------+------------------------------+
///        | NAME       | domain name  | MUST be 0 (root domain)      |
///        | TYPE       | u_int16_t    | OPT (41)                     |
///        | CLASS      | u_int16_t    | requestor's UDP payload size |
///        | TTL        | u_int32_t    | extended RCODE and flags     |
///        | RDLEN      | u_int16_t    | length of all RDATA          |
///        | RDATA      | octet stream | {attribute,value} pairs      |
///        +------------+--------------+------------------------------+
///
///                                OPT RR Format
///
///    The variable part of an OPT RR may contain zero or more options in
///    the RDATA.  Each option MUST be treated as a bit field.  Each option
///    is encoded as:
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
///
///    OPTION-CODE
///       Assigned by the Expert Review process as defined by the DNSEXT
///       working group and the IESG.
///
///    OPTION-LENGTH
///       Size (in octets) of OPTION-DATA.
///
///    OPTION-DATA
///       Varies per OPTION-CODE.  MUST be treated as a bit field.
///
///    The order of appearance of option tuples is not defined.  If one
///    option modifies the behaviour of another or multiple options are
///    related to one another in some way, they have the same effect
///    regardless of ordering in the RDATA wire encoding.
///
///    Any OPTION-CODE values not understood by a responder or requestor
///    MUST be ignored.  Specifications of such options might wish to
///    include some kind of signaled acknowledgement.  For example, an
///    option specification might say that if a responder sees and supports
///    option XYZ, it MUST include option XYZ in its response.
///
/// 6.1.3.  OPT Record TTL Field Use
///
///    The extended RCODE and flags, which OPT stores in the RR Time to Live
///    (TTL) field, are structured as follows:
///
///                   +0 (MSB)                            +1 (LSB)
///        +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
///     0: |         EXTENDED-RCODE        |            VERSION            |
///        +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
///     2: | DO|                           Z                               |
///        +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
///
///    EXTENDED-RCODE
///       Forms the upper 8 bits of extended 12-bit RCODE (together with the
///       4 bits defined in [RFC1035].  Note that EXTENDED-RCODE value 0
///       indicates that an unextended RCODE is in use (values 0 through
///       15).
///
///    VERSION
///       Indicates the implementation level of the setter.  Full
///       conformance with this specification is indicated by version '0'.
///       Requestors are encouraged to set this to the lowest implemented
///       level capable of expressing a transaction, to minimise the
///       responder and network load of discovering the greatest common
///       implementation level between requestor and responder.  A
///       requestor's version numbering strategy MAY ideally be a run-time
///       configuration option.
///       If a responder does not implement the VERSION level of the
///       request, then it MUST respond with RCODE=BADVERS.  All responses
///       MUST be limited in format to the VERSION level of the request, but
///       the VERSION of each response SHOULD be the highest implementation
///       level of the responder.  In this way, a requestor will learn the
///       implementation level of a responder as a side effect of every
///       response, including error responses and including RCODE=BADVERS.
///
/// 6.1.4.  Flags
///
///    DO
///       DNSSEC OK bit as defined by [RFC3225].
///
///    Z
///       Set to zero by senders and ignored by receivers, unless modified
///       in a subsequent specification.
/// ```
public struct OPT: Sendable {
    public var options: [(EDNSCode, EDNSOption)]

    public init(options: [(EDNSCode, EDNSOption)]) {
        self.options = options
    }
}

extension OPT {
    enum OptReadingState: ~Copyable {
        case readCode
        case code(code: EDNSCode)
        case data(code: EDNSCode, length: UInt16)
    }

    package init(from buffer: inout DNSBuffer) throws {
        var state: OptReadingState = .readCode
        self.options = []

        while buffer.readableBytes != 0 {
            switch consume state {
            case .readCode:
                state = .code(code: try EDNSCode(from: &buffer))
            case .code(let code):
                let length = try buffer.readInteger(as: UInt16.self).unwrap(
                    or: .failedToRead("OPT.length", buffer)
                )
                switch length {
                case 0:
                    options.append((code, try EDNSOption(from: &buffer, code: code)))
                    state = .readCode
                default:
                    state = .data(
                        code: code,
                        length: length
                    )
                }
            case .data(let code, let length):
                /// `length` is a `UInt16`, so it's safe to convert to Int
                var bytes = try buffer.readSlice(length: Int(length)).unwrap(
                    or: .failedToRead("OPT.data", buffer)
                )
                options.append((code, try EDNSOption(from: &bytes, code: code)))
                state = .readCode
            }
        }

        switch state {
        case .readCode: break
        default:
            /// FIXME: do something about warnings logs
            print("Incomplete or poorly formatted EDNS options")
            options.removeAll(keepingCapacity: false)
        }
    }
}

extension OPT {
    package func encode(into buffer: inout DNSBuffer) throws {
        for (code, option) in self.options {
            code.encode(into: &buffer)
            try option.encode(into: &buffer)
        }
    }
}

extension OPT {
    package init(fromOPTRData rdata: consuming RData) {
        /// Checks update0 and NULL's `recordType`s too, unlike the assertionFailure below
        assert(rdata.recordType == .OPT)
        switch rdata {
        case .OPT(let opt):
            self = opt
        case .Update0, .NULL:
            self.options = []
        default:
            self.options = []
            assertionFailure("Relies on a gurantee that the RData is only OPT, but was: \(rdata)")
        }
    }
}
