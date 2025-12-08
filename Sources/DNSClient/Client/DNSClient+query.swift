public import DNSModels

@available(swiftDNSApplePlatforms 13, *)
extension DNSClient {
    @inlinable
    func querySpecialized<RDataType: RDataConvertible>(
        message factory: consuming MessageFactory<RDataType>
    ) async throws -> SpecializedMessage<RDataType> {
        try SpecializedMessage<RDataType>(
            message: await self.query(message: factory)
        )
    }

    /// FIXME: Some of these aren't even queryable in practice. Clean those up.

    @inlinable
    public func queryA(
        message factory: consuming MessageFactory<A>
    ) async throws -> SpecializedMessage<A> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryAAAA(
        message factory: consuming MessageFactory<AAAA>
    ) async throws -> SpecializedMessage<AAAA> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryCAA(
        message factory: consuming MessageFactory<CAA>
    ) async throws -> SpecializedMessage<CAA> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryCDS(
        message factory: consuming MessageFactory<CDS>
    ) async throws -> SpecializedMessage<CDS> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryCDNSKEY(
        message factory: consuming MessageFactory<CDNSKEY>
    ) async throws -> SpecializedMessage<CDNSKEY> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryCERT(
        message factory: consuming MessageFactory<CERT>
    ) async throws -> SpecializedMessage<CERT> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryCNAME(
        message factory: consuming MessageFactory<CNAME>
    ) async throws -> SpecializedMessage<CNAME> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryCSYNC(
        message factory: consuming MessageFactory<CSYNC>
    ) async throws -> SpecializedMessage<CSYNC> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryDNSKEY(
        message factory: consuming MessageFactory<DNSKEY>
    ) async throws -> SpecializedMessage<DNSKEY> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryDS(
        message factory: consuming MessageFactory<DS>
    ) async throws -> SpecializedMessage<DS> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryHINFO(
        message factory: consuming MessageFactory<HINFO>
    ) async throws -> SpecializedMessage<HINFO> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryHTTPS(
        message factory: consuming MessageFactory<HTTPS>
    ) async throws -> SpecializedMessage<HTTPS> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryKEY(
        message factory: consuming MessageFactory<KEY>
    ) async throws -> SpecializedMessage<KEY> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryMX(
        message factory: consuming MessageFactory<MX>
    ) async throws -> SpecializedMessage<MX> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryNAPTR(
        message factory: consuming MessageFactory<NAPTR>
    ) async throws -> SpecializedMessage<NAPTR> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryNS(
        message factory: consuming MessageFactory<NS>
    ) async throws -> SpecializedMessage<NS> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryNSEC(
        message factory: consuming MessageFactory<NSEC>
    ) async throws -> SpecializedMessage<NSEC> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryNSEC3(
        message factory: consuming MessageFactory<NSEC3>
    ) async throws -> SpecializedMessage<NSEC3> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryNSEC3PARAM(
        message factory: consuming MessageFactory<NSEC3PARAM>
    ) async throws -> SpecializedMessage<NSEC3PARAM> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryNULL(
        message factory: consuming MessageFactory<NULL>
    ) async throws -> SpecializedMessage<NULL> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryOPENPGPKEY(
        message factory: consuming MessageFactory<OPENPGPKEY>
    ) async throws -> SpecializedMessage<OPENPGPKEY> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryOPT(
        message factory: consuming MessageFactory<OPT>
    ) async throws -> SpecializedMessage<OPT> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryPTR(
        message factory: consuming MessageFactory<PTR>
    ) async throws -> SpecializedMessage<PTR> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryRRSIG(
        message factory: consuming MessageFactory<RRSIG>
    ) async throws -> SpecializedMessage<RRSIG> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func querySIG(
        message factory: consuming MessageFactory<SIG>
    ) async throws -> SpecializedMessage<SIG> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func querySOA(
        message factory: consuming MessageFactory<SOA>
    ) async throws -> SpecializedMessage<SOA> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func querySRV(
        message factory: consuming MessageFactory<SRV>
    ) async throws -> SpecializedMessage<SRV> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func querySSHFP(
        message factory: consuming MessageFactory<SSHFP>
    ) async throws -> SpecializedMessage<SSHFP> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func querySVCB(
        message factory: consuming MessageFactory<SVCB>
    ) async throws -> SpecializedMessage<SVCB> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryTLSA(
        message factory: consuming MessageFactory<TLSA>
    ) async throws -> SpecializedMessage<TLSA> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryTSIG(
        message factory: consuming MessageFactory<TSIG>
    ) async throws -> SpecializedMessage<TSIG> {
        try await self.querySpecialized(message: factory)
    }

    @inlinable
    public func queryTXT(
        message factory: consuming MessageFactory<TXT>
    ) async throws -> SpecializedMessage<TXT> {
        try await self.querySpecialized(message: factory)
    }
}
