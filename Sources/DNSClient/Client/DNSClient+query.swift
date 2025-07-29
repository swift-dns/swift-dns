public import DNSModels

@available(swiftDNSApplePlatforms 26.0, *)
extension DNSClient {
    @usableFromInline
    func querySpecialized<RDataType: RDataConvertible>(
        message factory: consuming MessageFactory<RDataType>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind
    ) async throws -> SpecializedMessage<RDataType> {
        try SpecializedMessage(
            message: await self.query(
                message: factory,
                options: options,
                channelKind: channelKind
            )
        )
    }

    /// FIXME: Some of these aren't even queryable in practice. Clean those up.

    @inlinable
    public func queryA(
        message factory: consuming MessageFactory<A>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<A> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryAAAA(
        message factory: consuming MessageFactory<AAAA>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<AAAA> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryCAA(
        message factory: consuming MessageFactory<CAA>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<CAA> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryCDS(
        message factory: consuming MessageFactory<CDS>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<CDS> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryCDNSKEY(
        message factory: consuming MessageFactory<CDNSKEY>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<CDNSKEY> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryCERT(
        message factory: consuming MessageFactory<CERT>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<CERT> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryCNAME(
        message factory: consuming MessageFactory<CNAME>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<CNAME> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryCSYNC(
        message factory: consuming MessageFactory<CSYNC>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<CSYNC> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryDNSKEY(
        message factory: consuming MessageFactory<DNSKEY>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<DNSKEY> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryDS(
        message factory: consuming MessageFactory<DS>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<DS> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryHINFO(
        message factory: consuming MessageFactory<HINFO>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<HINFO> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryHTTPS(
        message factory: consuming MessageFactory<HTTPS>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<HTTPS> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryKEY(
        message factory: consuming MessageFactory<KEY>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<KEY> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryMX(
        message factory: consuming MessageFactory<MX>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<MX> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryNAPTR(
        message factory: consuming MessageFactory<NAPTR>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<NAPTR> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryNS(
        message factory: consuming MessageFactory<NS>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<NS> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryNSEC(
        message factory: consuming MessageFactory<NSEC>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<NSEC> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryNSEC3(
        message factory: consuming MessageFactory<NSEC3>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<NSEC3> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryNSEC3PARAM(
        message factory: consuming MessageFactory<NSEC3PARAM>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<NSEC3PARAM> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryNULL(
        message factory: consuming MessageFactory<NULL>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<NULL> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryOPENPGPKEY(
        message factory: consuming MessageFactory<OPENPGPKEY>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<OPENPGPKEY> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryOPT(
        message factory: consuming MessageFactory<OPT>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<OPT> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryPTR(
        message factory: consuming MessageFactory<PTR>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<PTR> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryRRSIG(
        message factory: consuming MessageFactory<RRSIG>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<RRSIG> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func querySIG(
        message factory: consuming MessageFactory<SIG>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<SIG> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func querySOA(
        message factory: consuming MessageFactory<SOA>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<SOA> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func querySRV(
        message factory: consuming MessageFactory<SRV>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<SRV> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func querySSHFP(
        message factory: consuming MessageFactory<SSHFP>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<SSHFP> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func querySVCB(
        message factory: consuming MessageFactory<SVCB>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<SVCB> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryTLSA(
        message factory: consuming MessageFactory<TLSA>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<TLSA> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryTSIG(
        message factory: consuming MessageFactory<TSIG>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<TSIG> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }

    @inlinable
    public func queryTXT(
        message factory: consuming MessageFactory<TXT>,
        options: DNSRequestOptions = .init(),
        channelKind: QueryChannelKind = .udp
    ) async throws -> SpecializedMessage<TXT> {
        try await self.querySpecialized(
            message: factory,
            options: options,
            channelKind: channelKind
        )
    }
}
