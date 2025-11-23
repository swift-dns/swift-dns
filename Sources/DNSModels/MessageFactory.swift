public import SwiftIDNA

@available(swiftDNSApplePlatforms 13, *)
public struct MessageFactory<QueryType: Queryable>: ~Copyable, Sendable {
    /// private
    @usableFromInline
    var message: Message

    /// Directly initializes the factory.
    /// Use convenience methods such as `forQuery(domainName:recursionDesired:checkingDisabled:)` instead.
    @inlinable
    init(message: consuming Message) {
        self.message = message
    }

    package consuming func takeMessage() -> Message {
        self.message
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
                    additionalCount: 0
                ),
                queries: [
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
                edns: nil
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
        return Self.forQuery(
            domainName: domainName,
            recursionDesired: recursionDesired,
            checkingDisabled: checkingDisabled
        )
    }

    @inlinable
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

    @inlinable
    public mutating func apply(requestID: UInt16) {
        self.message.header.id = requestID
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension MessageFactory {
    package func __testing_copyMessage() -> Message {
        self.message
    }
}
