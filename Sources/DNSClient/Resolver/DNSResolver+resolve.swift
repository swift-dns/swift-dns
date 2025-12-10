@available(swiftDNSApplePlatforms 13, *)
extension DNSResolver {
    public struct ResolutionFailure: Sendable, Error {
        public enum Reason: Sendable {
            case receivedUnexpectedRecordType(RecordType)
        }

        public let query: Message
        public let response: Message
        public let reason: Reason

        @inlinable
        init(query: Message, response: Message, reason: Reason) {
            self.query = query
            self.response = response
            self.reason = reason
        }
    }

    @inlinable
    public func resolveA(
        message factory: consuming MessageFactory<A>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<A> {
        var factory = factory
        while true {
            let (query, response) = try await self.client._query(
                message: factory.copy(),
                isolation: isolation
            )

            if response.answers.contains(where: { $0.recordType == .A }) {
                return SpecializedMessage<A>(message: response)
            }

            switch response.answers.first?.rdata {
            case .none:
                return SpecializedMessage<A>(message: response)
            case .some(let rdata):
                switch rdata {
                case .CNAME(let cname):
                    /// FIXME: have a way to stop after certain number of tries
                    factory.setDomainName(to: cname.domainName)
                    continue
                case .A:
                    assertionFailure(
                        """
                        Should be impossible to reach here.
                        We already checked there are no A records in the response answers.
                        Query: \(query)
                        Response: \(response)
                        """
                    )
                    fallthrough
                default:
                    throw ResolutionFailure(
                        query: query,
                        response: response,
                        reason: .receivedUnexpectedRecordType(rdata.recordType)
                    )
                }
            }
        }
    }

    @inlinable
    public func resolveAAAA(
        message factory: consuming MessageFactory<AAAA>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<AAAA> {
        var factory = factory
        while true {
            let (query, response) = try await self.client._query(
                message: factory.copy(),
                isolation: isolation
            )

            if response.answers.contains(where: { $0.recordType == .AAAA }) {
                return SpecializedMessage<AAAA>(message: response)
            }

            switch response.answers.first?.rdata {
            case .none:
                return SpecializedMessage<AAAA>(message: response)
            case .some(let rdata):
                switch rdata {
                case .CNAME(let cname):
                    /// FIXME: have a way to stop after certain number of tries
                    factory.setDomainName(to: cname.domainName)
                    continue
                case .AAAA:
                    assertionFailure(
                        """
                        Should be impossible to reach here.
                        We already checked there are no AAAA records in the response answers.
                        Query: \(query)
                        Response: \(response)
                        """
                    )
                    fallthrough
                default:
                    throw ResolutionFailure(
                        query: query,
                        response: response,
                        reason: .receivedUnexpectedRecordType(rdata.recordType)
                    )
                }
            }
        }
    }
}
