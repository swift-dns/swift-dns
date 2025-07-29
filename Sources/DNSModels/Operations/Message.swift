import DNSCore

/// The basic request and response data structure, used for all DNS protocols.
///
/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
///
/// ```text
/// 4.1. Format
///
/// All communications inside of the domain protocol are carried in a single
/// format called a message.  The top level format of message is divided
/// into 5 sections (some of which are empty in certain cases) shown below:
///
///     +--------------------------+
///     |        Header            |
///     +--------------------------+
///     |  Question / Zone         | the question for the name server
///     +--------------------------+
///     |   Answer  / Prerequisite | RRs answering the question
///     +--------------------------+
///     | Authority / Update       | RRs pointing toward an authority
///     +--------------------------+
///     |      Additional          | RRs holding additional information
///     +--------------------------+
///
/// The header section is always present.  The header includes fields that
/// specify which of the remaining sections are present, and also specify
/// whether the message is a query or a response, a standard query or some
/// other opcode, etc.
///
/// The names of the sections after the header are derived from their use in
/// standard queries.  The question section contains fields that describe a
/// question to a name server.  These fields are a query type (QTYPE), a
/// query class (QCLASS), and a query domain name (QNAME).  The last three
/// sections have the same format: a possibly empty list of concatenated
/// resource records (RRs).  The answer section contains RRs that answer the
/// question; the authority section contains RRs that point toward an
/// authoritative name server; the additional records section contains RRs
/// which relate to the query, but are not strictly answers for the
/// question.
/// ```
@available(swiftDNSApplePlatforms 26, *)
public struct Message: Sendable {
    public var header: Header
    public var queries: TinyFastSequence<Query>
    public var answers: TinyFastSequence<Record>
    public var nameServers: TinyFastSequence<Record>
    public var additionals: TinyFastSequence<Record>
    public var signature: TinyFastSequence<Record>
    public var edns: EDNS?

    @usableFromInline
    package init(
        header: Header,
        queries: TinyFastSequence<Query>,
        answers: TinyFastSequence<Record>,
        nameServers: TinyFastSequence<Record>,
        additionals: TinyFastSequence<Record>,
        signature: TinyFastSequence<Record>,
        edns: EDNS?
    ) {
        self.header = header
        self.queries = queries
        self.answers = answers
        self.nameServers = nameServers
        self.additionals = additionals
        self.signature = signature
        self.edns = edns
    }
}

// FIXME: read and write using a dedicated reader/writer

@available(swiftDNSApplePlatforms 26, *)
extension Message {
    package init(from buffer: inout DNSBuffer) throws {
        self.header = try Header(from: &buffer)

        self.queries = TinyFastSequence<Query>()
        self.queries.reserveCapacity(Int(self.header.queryCount))
        for _ in 0..<header.queryCount {
            self.queries.append(try Query(from: &buffer))  // FIXME: this is not efficient
        }

        // TODO: reserve capacity and provide the array as `inout` for the function to fill?

        self.answers = try [Record].from(
            buffer: &buffer,
            count: header.answerCount,
            isAdditional: false
        ).records

        self.nameServers = try [Record].from(
            buffer: &buffer,
            count: header.nameServerCount,
            isAdditional: false
        ).records

        (self.additionals, self.edns, self.signature) = try [Record].from(
            buffer: &buffer,
            count: header.additionalCount,
            isAdditional: true
        )

        if let rcodeHigh = self.edns?.rcodeHigh {
            self.header.responseCode = .init(
                high: rcodeHigh,
                low: self.header.responseCode.low
            )
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension Message {
    package consuming func encode(into buffer: inout DNSBuffer) throws {
        debugOnly {
            if let edns = self.edns {
                /// Assert EDNS RCODE is the same as the response code high.
                assert(
                    self.header.responseCode.high == edns.rcodeHigh,
                    "eds.rcodeHigh '\(edns.rcodeHigh)' must match responseCode.high '\(self.header.responseCode.high)'"
                )
            }
        }
        /// TODO: assert/throws on header-count-properties mismatch with the actual counts?
        /// TODO: can reserve capacity upfront with some smartiness?
        self.header.encode(into: &buffer)
        for query in self.queries {
            try query.encode(into: &buffer)
        }
        for answer in self.answers {
            try answer.encode(into: &buffer)
        }
        for nameServer in self.nameServers {
            try nameServer.encode(into: &buffer)
        }
        for additional in self.additionals {
            try additional.encode(into: &buffer)
        }
        if let edns = self.edns {
            try edns.toRecord().encode(into: &buffer)
        }
        for signature in self.signature {
            try signature.encode(into: &buffer)
        }
    }
}
