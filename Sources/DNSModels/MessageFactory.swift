public struct MessageFactory<QueryType: Queryable> {
    public var message: Message

    /// Directly initilizes the factory.
    /// This is not recommended.
    /// Use convenience methods such as `forQuery(name:recursionDesired:checkingDisabled:)` instead.
    @inlinable
    public init(message: Message) {
        self.message = message
    }

    /// Creates a message for a query.
    @inlinable
    public static func forQuery(
        name: Name,
        recursionDesired: Bool = true,
        checkingDisabled: Bool = false,
    ) -> Self {
        self.init(
            message: Message(
                header: Header(
                    id: .random(in: .min ... .max),
                    messageType: .Query,
                    opCode: .Query,
                    authoritative: false,
                    truncation: false,
                    recursionDesired: recursionDesired,
                    recursionAvailable: false,
                    authenticData: true,
                    checkingDisabled: checkingDisabled,
                    responseCode: .NoError,
                    queryCount: 1,
                    answerCount: 0,
                    nameServerCount: 0,
                    additionalCount: 0
                ),
                queries: [
                    Query(
                        name: name,
                        queryType: QueryType.recordType,
                        queryClass: QueryType.dnsClass
                    )
                ],
                answers: [],
                nameServers: [],
                additionals: [],
                signature: [],
                edns: nil
            )
        )
    }

    /// Creates a message for a query.
    @inlinable
    public static func forQuery(
        name: String,
        idnaConfiguration: IDNA.Configuration = .default,
        recursionDesired: Bool = true,
        checkingDisabled: Bool = false,
    ) throws -> Self {
        let name = try Name(domainName: name, idnaConfiguration: idnaConfiguration)
        return Self.forQuery(
            name: name,
            recursionDesired: recursionDesired,
            checkingDisabled: checkingDisabled
        )
    }

    public mutating func apply(options: DNSRequestOptions) {
        if options.contains(.edns) {
            self.message.header.additionalCount += 1
            self.message.edns = EDNS(
                rcodeHigh: 0,
                version: 0,
                flags: .init(dnssecOk: false, z: 0),
                maxPayload: 4096,
                options: OPT(options: [])
            )
        }
    }
}
