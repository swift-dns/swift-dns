public import DNSModels
public import Logging
/// FIXME: as of writing this comment we only need EventLoopGroup as public, but Swift 6.2 doesn't
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

    public func query(message: Message) async throws -> Message {
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
            queryPool.insert(message, continuation: continuation)
            // FIXME: what if the channel is closed and rejects this write?
            channel.writeAndFlush(message).whenComplete { result in
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
    @inlinable
    public func query<RDataType: RDataConvertible>(
        message: Message
    ) async throws -> SpecializedMessage<RDataType> {
        try SpecializedMessage(
            message: await query(message: message)
        )
    }

    public func queryA(message: Message) async throws -> SpecializedMessage<A> {
        try await self.query(message: message)
    }

    public func queryAAAA(message: Message) async throws -> SpecializedMessage<AAAA> {
        try await self.query(message: message)
    }

    public func queryCAA(message: Message) async throws -> SpecializedMessage<CAA> {
        try await self.query(message: message)
    }

    public func queryCDS(message: Message) async throws -> SpecializedMessage<CDS> {
        try await self.query(message: message)
    }

    public func queryCDNSKEY(message: Message) async throws -> SpecializedMessage<CDNSKEY> {
        try await self.query(message: message)
    }

    public func queryCERT(message: Message) async throws -> SpecializedMessage<CERT> {
        try await self.query(message: message)
    }

    public func queryCNAME(message: Message) async throws -> SpecializedMessage<CNAME> {
        try await self.query(message: message)
    }

    public func queryCSYNC(message: Message) async throws -> SpecializedMessage<CSYNC> {
        try await self.query(message: message)
    }

    public func queryDNSKEY(message: Message) async throws -> SpecializedMessage<DNSKEY> {
        try await self.query(message: message)
    }

    public func queryDS(message: Message) async throws -> SpecializedMessage<DS> {
        try await self.query(message: message)
    }

    public func queryHINFO(message: Message) async throws -> SpecializedMessage<HINFO> {
        try await self.query(message: message)
    }

    public func queryHTTPS(message: Message) async throws -> SpecializedMessage<HTTPS> {
        try await self.query(message: message)
    }

    public func queryKEY(message: Message) async throws -> SpecializedMessage<KEY> {
        try await self.query(message: message)
    }

    public func queryMX(message: Message) async throws -> SpecializedMessage<MX> {
        try await self.query(message: message)
    }

    public func queryNAPTR(message: Message) async throws -> SpecializedMessage<NAPTR> {
        try await self.query(message: message)
    }

    public func queryNS(message: Message) async throws -> SpecializedMessage<NS> {
        try await self.query(message: message)
    }

    public func queryNSEC(message: Message) async throws -> SpecializedMessage<NSEC> {
        try await self.query(message: message)
    }

    public func queryNSEC3(message: Message) async throws -> SpecializedMessage<NSEC3> {
        try await self.query(message: message)
    }

    public func queryNSEC3PARAM(message: Message) async throws -> SpecializedMessage<NSEC3PARAM> {
        try await self.query(message: message)
    }

    public func queryNULL(message: Message) async throws -> SpecializedMessage<NULL> {
        try await self.query(message: message)
    }

    public func queryOPENPGPKEY(message: Message) async throws -> SpecializedMessage<OPENPGPKEY> {
        try await self.query(message: message)
    }

    public func queryOPT(message: Message) async throws -> SpecializedMessage<OPT> {
        try await self.query(message: message)
    }

    public func queryPTR(message: Message) async throws -> SpecializedMessage<PTR> {
        try await self.query(message: message)
    }

    public func queryRRSIG(message: Message) async throws -> SpecializedMessage<RRSIG> {
        try await self.query(message: message)
    }

    public func querySIG(message: Message) async throws -> SpecializedMessage<SIG> {
        try await self.query(message: message)
    }

    public func querySOA(message: Message) async throws -> SpecializedMessage<SOA> {
        try await self.query(message: message)
    }

    public func querySRV(message: Message) async throws -> SpecializedMessage<SRV> {
        try await self.query(message: message)
    }

    public func querySSHFP(message: Message) async throws -> SpecializedMessage<SSHFP> {
        try await self.query(message: message)
    }

    public func querySVCB(message: Message) async throws -> SpecializedMessage<SVCB> {
        try await self.query(message: message)
    }

    public func queryTLSA(message: Message) async throws -> SpecializedMessage<TLSA> {
        try await self.query(message: message)
    }

    public func queryTSIG(message: Message) async throws -> SpecializedMessage<TSIG> {
        try await self.query(message: message)
    }

    public func queryTXT(message: Message) async throws -> SpecializedMessage<TXT> {
        try await self.query(message: message)
    }
}
