@available(swiftDNSApplePlatforms 13, *)
extension ForwardingDNSResolver: _DNSClientProtocol {
    @inlinable
    public func _querySpecialized<RDataType: RDataConvertible>(
        message factory: consuming MessageFactory<RDataType>
    ) async throws -> SpecializedMessage<RDataType> {
        let domainName = factory.query.domainName
        let checkingDisabled = factory.message.header.checkingDisabled
        if let cachedMessage = await self.cache.retrieve(
            domainName: domainName,
            checkingDisabled: checkingDisabled,
            useStaleCache: false
        ) {
            return SpecializedMessage<RDataType>(message: cachedMessage)
        }

        do {
            let response = try await self.client.query(message: factory)
            await self.cache.save(
                domainName: domainName,
                message: response
            )

            if response.header.responseCode == .ServFail,
                let staleMessage = await self.cache.retrieve(
                    domainName: domainName,
                    checkingDisabled: checkingDisabled,
                    useStaleCache: true
                )
            {
                return SpecializedMessage<RDataType>(message: staleMessage)
            }

            return SpecializedMessage<RDataType>(message: response)
        } catch {
            if let staleMessage = await self.cache.retrieve(
                domainName: domainName,
                checkingDisabled: checkingDisabled,
                useStaleCache: true
            ) {
                return SpecializedMessage<RDataType>(message: staleMessage)
            }

            /// TODO: should throw an error that indicates we failed from reading stale cache even?
            throw error
        }
    }
}
