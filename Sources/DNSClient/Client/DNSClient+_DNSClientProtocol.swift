@available(swiftDNSApplePlatforms 13, *)
extension DNSClient: _DNSClientProtocol {
    @inlinable
    public func _querySpecialized<RDataType: RDataConvertible>(
        message factory: consuming MessageFactory<RDataType>,
        isolation: isolated (any Actor)?
    ) async throws -> SpecializedMessage<RDataType> {
        try SpecializedMessage<RDataType>(
            message: await self.query(
                message: factory,
                isolation: isolation
            ).response
        )
    }
}
