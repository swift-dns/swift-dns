public import DNSModels
public import Logging
/// as of writing this comment we only need EventLoopGroup as public, but Swift 6.2 doesn't
/// accept multiple access levels for the same module, so can't import the symbols one by one with
/// different access levels.
public import NIOCore
import NIOPosix

public struct DNSClient {
    public var connectionTarget: ConnectionTarget
    let eventLoopGroup: any EventLoopGroup
    let queryPool: QueryPool
    let logger: Logger

    /// FIXME: shouldn't expose EventLoopGroup anymore?
    public init(
        connectionTarget: ConnectionTarget,
        eventLoopGroup: any EventLoopGroup,
        logger: Logger = .noopLogger
    ) {
        self.connectionTarget = connectionTarget
        self.eventLoopGroup = eventLoopGroup
        self.queryPool = QueryPool()
        self.logger = logger
    }

    public init(
        connectionTarget: ConnectionTarget,
        logger: Logger = .noopLogger
    ) {
        self.connectionTarget = connectionTarget
        self.eventLoopGroup = MultiThreadedEventLoopGroup.singleton
        self.queryPool = QueryPool()
        self.logger = logger
    }

    public func query<RDataType: RDataConvertible>(
        message factory: MessageFactory<RDataType>,
        options: DNSRequestOptions = .init()
    ) async throws -> Message {
        var factory = factory
        factory.apply(options: options)

        // FIXME: catch connection target to socket address translation errors
        let connectionFactory = try ConnectionFactory(
            queryPool: queryPool,
            connectionTarget: connectionTarget
        )
        /// FIXME: use a connection pool and all
        let channel = try await connectionFactory.makeChannel(
            deadline: .now() + .seconds(10),
            eventLoop: eventLoopGroup.next(),
            logger: logger
        ).get()
        return try await withCheckedThrowingContinuation { (continuation: QueryPool.Continuation) in
            queryPool.insert(factory.message, continuation: continuation)
            // FIXME: what if the channel is closed and rejects this write?
            channel.writeAndFlush(factory.message).whenComplete { result in
                switch result {
                case .success:
                    // Good
                    break
                case .failure(let error):
                    // FIXME: should have a better way to handle this
                    preconditionFailure(
                        "Failed to write message: \(String(reflecting: error))"
                    )
                }
            }
        }
    }
}

extension DNSClient {
    @usableFromInline
    func querySpecialized<RDataType: RDataConvertible>(
        message factory: MessageFactory<RDataType>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<RDataType> {
        try SpecializedMessage(
            message: await query(message: factory, options: options)
        )
    }

    /// FIXME: A lot of these aren't even queryable in practice. Clean those up.

    @inlinable
    public func queryA(
        message factory: MessageFactory<A>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<A> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryAAAA(
        message factory: MessageFactory<AAAA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<AAAA> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCAA(
        message factory: MessageFactory<CAA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CAA> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCDS(
        message factory: MessageFactory<CDS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CDS> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCDNSKEY(
        message factory: MessageFactory<CDNSKEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CDNSKEY> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCERT(
        message factory: MessageFactory<CERT>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CERT> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCNAME(
        message factory: MessageFactory<CNAME>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CNAME> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCSYNC(
        message factory: MessageFactory<CSYNC>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CSYNC> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryDNSKEY(
        message factory: MessageFactory<DNSKEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<DNSKEY> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryDS(
        message factory: MessageFactory<DS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<DS> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryHINFO(
        message factory: MessageFactory<HINFO>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<HINFO> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryHTTPS(
        message factory: MessageFactory<HTTPS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<HTTPS> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryKEY(
        message factory: MessageFactory<KEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<KEY> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryMX(
        message factory: MessageFactory<MX>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<MX> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNAPTR(
        message factory: MessageFactory<NAPTR>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NAPTR> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNS(
        message factory: MessageFactory<NS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NS> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNSEC(
        message factory: MessageFactory<NSEC>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NSEC> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNSEC3(
        message factory: MessageFactory<NSEC3>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NSEC3> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNSEC3PARAM(
        message factory: MessageFactory<NSEC3PARAM>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NSEC3PARAM> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNULL(
        message factory: MessageFactory<NULL>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NULL> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryOPENPGPKEY(
        message factory: MessageFactory<OPENPGPKEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<OPENPGPKEY> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryOPT(
        message factory: MessageFactory<OPT>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<OPT> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryPTR(
        message factory: MessageFactory<PTR>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<PTR> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryRRSIG(
        message factory: MessageFactory<RRSIG>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<RRSIG> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func querySIG(
        message factory: MessageFactory<SIG>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SIG> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func querySOA(
        message factory: MessageFactory<SOA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SOA> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func querySRV(
        message factory: MessageFactory<SRV>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SRV> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func querySSHFP(
        message factory: MessageFactory<SSHFP>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SSHFP> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func querySVCB(
        message factory: MessageFactory<SVCB>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SVCB> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryTLSA(
        message factory: MessageFactory<TLSA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<TLSA> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryTSIG(
        message factory: MessageFactory<TSIG>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<TSIG> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryTXT(
        message factory: MessageFactory<TXT>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<TXT> {
        try await self.querySpecialized(message: factory, options: options)
    }
}
