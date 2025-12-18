/// NOT CONSIDERED PART OF THE PUBLIC API. NOT FOR PUBLIC USE.
/// Used for synthesizing some query functions in DNS client and resolver types.
@available(swiftDNSApplePlatforms 10.15, *)
public protocol _DNSClientProtocol {
    @inlinable
    func _querySpecialized<RDataType: RDataConvertible>(
        message factory: consuming MessageFactory<RDataType>,
        isolation: isolated (any Actor)?
    ) async throws -> SpecializedMessage<RDataType>
}

@available(swiftDNSApplePlatforms 10.15, *)
extension _DNSClientProtocol {
    @inlinable
    public func queryA(
        message factory: consuming MessageFactory<A>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<A> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryAAAA(
        message factory: consuming MessageFactory<AAAA>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<AAAA> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryCAA(
        message factory: consuming MessageFactory<CAA>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<CAA> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryCDS(
        message factory: consuming MessageFactory<CDS>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<CDS> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryCDNSKEY(
        message factory: consuming MessageFactory<CDNSKEY>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<CDNSKEY> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryCERT(
        message factory: consuming MessageFactory<CERT>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<CERT> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryCNAME(
        message factory: consuming MessageFactory<CNAME>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<CNAME> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryCSYNC(
        message factory: consuming MessageFactory<CSYNC>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<CSYNC> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryDNSKEY(
        message factory: consuming MessageFactory<DNSKEY>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<DNSKEY> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryDS(
        message factory: consuming MessageFactory<DS>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<DS> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryHINFO(
        message factory: consuming MessageFactory<HINFO>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<HINFO> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryHTTPS(
        message factory: consuming MessageFactory<HTTPS>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<HTTPS> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryKEY(
        message factory: consuming MessageFactory<KEY>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<KEY> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryMX(
        message factory: consuming MessageFactory<MX>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<MX> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryNAPTR(
        message factory: consuming MessageFactory<NAPTR>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<NAPTR> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryNS(
        message factory: consuming MessageFactory<NS>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<NS> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryNSEC(
        message factory: consuming MessageFactory<NSEC>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<NSEC> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryNSEC3(
        message factory: consuming MessageFactory<NSEC3>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<NSEC3> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryNSEC3PARAM(
        message factory: consuming MessageFactory<NSEC3PARAM>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<NSEC3PARAM> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryNULL(
        message factory: consuming MessageFactory<NULL>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<NULL> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryOPENPGPKEY(
        message factory: consuming MessageFactory<OPENPGPKEY>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<OPENPGPKEY> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryOPT(
        message factory: consuming MessageFactory<OPT>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<OPT> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryPTR(
        message factory: consuming MessageFactory<PTR>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<PTR> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryRRSIG(
        message factory: consuming MessageFactory<RRSIG>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<RRSIG> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func querySIG(
        message factory: consuming MessageFactory<SIG>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<SIG> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func querySOA(
        message factory: consuming MessageFactory<SOA>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<SOA> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func querySRV(
        message factory: consuming MessageFactory<SRV>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<SRV> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func querySSHFP(
        message factory: consuming MessageFactory<SSHFP>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<SSHFP> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func querySVCB(
        message factory: consuming MessageFactory<SVCB>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<SVCB> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryTLSA(
        message factory: consuming MessageFactory<TLSA>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<TLSA> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryTSIG(
        message factory: consuming MessageFactory<TSIG>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<TSIG> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }

    @inlinable
    public func queryTXT(
        message factory: consuming MessageFactory<TXT>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> SpecializedMessage<TXT> {
        try await self._querySpecialized(message: factory, isolation: isolation)
    }
}
