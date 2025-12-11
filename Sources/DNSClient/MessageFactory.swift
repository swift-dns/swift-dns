public import DNSModels
public import SwiftIDNA

@available(swiftDNSApplePlatforms 10.15, *)
public struct MessageFactory<QueryType: Queryable>: ~Copyable, Sendable {
    /// private
    @usableFromInline
    var message: Message

    /// Directly initializes the factory.
    /// Use convenience methods such as `forQuery(domainName:recursionDesired:checkingDisabled:)` instead.
    @inlinable
    init(message: consuming Message) {
        self.message = message
        assert(
            self.message.queries.count == 1,
            """
            Message must have at least 1 queries.
            More than 1 queries is not currently supported.
            Get in touch with me if you need support for multiple queries.
            """
        )
    }

    @inlinable
    package consuming func takeMessage() -> Message {
        self.message
    }

    @inlinable
    package func copy() -> Self {
        Self(message: self.message)
    }

    /// Creates a message for a query.
    @inlinable
    public static func forQuery(
        domainName: DomainName,
        recursionDesired: Bool = true,
        checkingDisabled: Bool = false,
    ) -> Self {
        self.init(
            message: Message(
                header: Header(
                    /// Channel handler will reassign an appropriate id
                    id: 0,
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
                    additionalCount: 1
                ),
                queries: [
                    /// A bunch of other places depend on the fact that after calling this func,
                    /// 1 and exactly 1 queries exist.
                    Query(
                        domainName: domainName,
                        queryType: QueryType.recordType,
                        queryClass: QueryType.dnsClass
                    )
                ],
                answers: [],
                nameServers: [],
                additionals: [],
                signature: [],
                edns: EDNS(
                    rcodeHigh: 0,
                    version: 0,
                    flags: .init(dnssecOk: false, z: 0),
                    maxPayload: 4096,
                    options: OPT(options: [])
                )
            )
        )
    }

    /// Creates a message for a query.
    @inlinable
    public static func forQuery(
        domainName: String,
        idnaConfiguration: IDNA.Configuration = .default,
        recursionDesired: Bool = true,
        checkingDisabled: Bool = false,
    ) throws -> Self {
        let domainName = try DomainName(domainName, idnaConfiguration: idnaConfiguration)
        return .forQuery(
            domainName: domainName,
            recursionDesired: recursionDesired,
            checkingDisabled: checkingDisabled
        )
    }

    @inlinable
    public mutating func apply(requestID: UInt16) {
        self.message.header.id = requestID
    }

    @usableFromInline
    package mutating func setDomainName(
        to newDomainName: DomainName
    ) {
        /// Safe to subscript at index 0 after `forQuery` has been called
        self.message.queries[0].domainName = newDomainName
    }
}
