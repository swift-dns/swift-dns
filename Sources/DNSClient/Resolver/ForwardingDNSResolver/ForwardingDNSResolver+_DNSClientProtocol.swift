@available(swiftDNSApplePlatforms 13, *)
extension ForwardingDNSResolver: _DNSClientProtocol {
    @inlinable
    public func _querySpecialized<RDataType: RDataConvertible>(
        message factory: consuming MessageFactory<RDataType>
    ) async throws -> SpecializedMessage<RDataType> {
        let domainName = factory.query.domainName
        if let cachedMessage = await self.cache.retrieve(
            domainName: domainName,
            checkingDisabled: factory.message.header.checkingDisabled
        ) {
            return SpecializedMessage<RDataType>(message: cachedMessage)
        }

        let response = try await self.client.query(message: factory)
        await self.cache.save(
            domainName: domainName,
            message: response
        )

        return SpecializedMessage<RDataType>(message: response)
    }
}
