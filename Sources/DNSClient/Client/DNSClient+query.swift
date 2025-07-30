public import DNSModels

@available(swiftDNSApplePlatforms 26, *)
extension DNSClient {
    @usableFromInline
    func querySpecialized<RDataType: RDataConvertible>(
        message factory: consuming MessageFactory<RDataType>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<RDataType> {
        try SpecializedMessage(
            message: await self.query(
                message: factory,
                options: options
            )
        )
    }

    /// FIXME: Some of these aren't even queryable in practice. Clean those up.

    @inlinable
    public func queryA(
        message factory: consuming MessageFactory<A>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<A> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryAAAA(
        message factory: consuming MessageFactory<AAAA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<AAAA> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryCAA(
        message factory: consuming MessageFactory<CAA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CAA> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryCDS(
        message factory: consuming MessageFactory<CDS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CDS> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryCDNSKEY(
        message factory: consuming MessageFactory<CDNSKEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CDNSKEY> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryCERT(
        message factory: consuming MessageFactory<CERT>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CERT> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryCNAME(
        message factory: consuming MessageFactory<CNAME>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CNAME> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryCSYNC(
        message factory: consuming MessageFactory<CSYNC>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CSYNC> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryDNSKEY(
        message factory: consuming MessageFactory<DNSKEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<DNSKEY> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryDS(
        message factory: consuming MessageFactory<DS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<DS> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryHINFO(
        message factory: consuming MessageFactory<HINFO>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<HINFO> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryHTTPS(
        message factory: consuming MessageFactory<HTTPS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<HTTPS> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryKEY(
        message factory: consuming MessageFactory<KEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<KEY> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryMX(
        message factory: consuming MessageFactory<MX>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<MX> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryNAPTR(
        message factory: consuming MessageFactory<NAPTR>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NAPTR> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryNS(
        message factory: consuming MessageFactory<NS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NS> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryNSEC(
        message factory: consuming MessageFactory<NSEC>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NSEC> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryNSEC3(
        message factory: consuming MessageFactory<NSEC3>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NSEC3> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryNSEC3PARAM(
        message factory: consuming MessageFactory<NSEC3PARAM>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NSEC3PARAM> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryNULL(
        message factory: consuming MessageFactory<NULL>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NULL> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryOPENPGPKEY(
        message factory: consuming MessageFactory<OPENPGPKEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<OPENPGPKEY> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryOPT(
        message factory: consuming MessageFactory<OPT>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<OPT> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryPTR(
        message factory: consuming MessageFactory<PTR>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<PTR> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryRRSIG(
        message factory: consuming MessageFactory<RRSIG>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<RRSIG> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func querySIG(
        message factory: consuming MessageFactory<SIG>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SIG> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func querySOA(
        message factory: consuming MessageFactory<SOA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SOA> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func querySRV(
        message factory: consuming MessageFactory<SRV>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SRV> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func querySSHFP(
        message factory: consuming MessageFactory<SSHFP>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SSHFP> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func querySVCB(
        message factory: consuming MessageFactory<SVCB>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SVCB> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryTLSA(
        message factory: consuming MessageFactory<TLSA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<TLSA> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryTSIG(
        message factory: consuming MessageFactory<TSIG>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<TSIG> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func queryTXT(
        message factory: consuming MessageFactory<TXT>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<TXT> {
        try await self.querySpecialized(
            message: factory,
            options: options
        )
    }
}
