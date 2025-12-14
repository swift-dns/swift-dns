@available(swiftDNSApplePlatforms 13, *)
extension _RecursiveDNSResolver {
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
        try await self.resolveFollowingCNAMEs(
            factory: factory,
            isolation: isolation
        )
    }

    @inlinable
    public func resolveAAAA(
        message factory: consuming MessageFactory<AAAA>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<AAAA> {
        try await self.resolveFollowingCNAMEs(
            factory: factory,
            isolation: isolation
        )
    }

    @inlinable
    func resolveFollowingCNAMEs<RDataType: RDataConvertible>(
        factory: consuming MessageFactory<RDataType>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<RDataType> {
        assert(
            RDataType.recordType != .CNAME,
            "No need to resolve following CNAMEs for CNAME records."
        )

        var factory = factory
        var cnameChain = TinyFastSequence<Record>()
        while true {
            let (query, _response) = try await self.client._query(
                message: factory.copy(),
                isolation: isolation
            )
            var response = _response

            if response.answers.contains(where: { $0.recordType == RDataType.recordType }) {
                appendingAnswerChain(to: &response, chain: &cnameChain)
                return SpecializedMessage<RDataType>(message: response)
            }

            guard let firstAnswerRecord = response.answers.first else {
                appendingAnswerChain(to: &response, chain: &cnameChain)
                /// Empty answers
                return SpecializedMessage<RDataType>(message: response)
            }

            switch firstAnswerRecord.rdata {
            case .CNAME(let cname):
                /// FIXME: have a way to stop after certain number of tries
                factory.setDomainName(to: cname.domainName)
                cnameChain.append(firstAnswerRecord)
                continue
            case let rdata where rdata.recordType == RDataType.recordType:
                assertionFailure("Cannot reach here")
                fallthrough
            default:
                throw ResolutionFailure(
                    query: query,
                    response: response,
                    reason: .receivedUnexpectedRecordType(firstAnswerRecord.recordType)
                )
            }
        }
    }

    @inlinable
    func appendingAnswerChain(
        to message: inout Message,
        chain: inout TinyFastSequence<Record>,
        isolation: isolated (any Actor)? = #isolation
    ) {
        if chain.isEmpty { return }
        chain.append(contentsOf: message.answers)
        /// `chain.count` is very unlikely to be greater than 65535: We don't consider it.
        message.header.answerCount = UInt16(chain.count)
        message.answers = chain
    }
}
