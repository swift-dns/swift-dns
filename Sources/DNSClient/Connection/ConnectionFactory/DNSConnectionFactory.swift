public import Logging
public import NIOCore

@available(swiftDNSApplePlatforms 13, *)
@usableFromInline
package struct DNSConnectionFactory: Sendable {
    @usableFromInline
    enum UnderlyingFactory: Sendable {
        case `default`(DefaultDNSConnectionFactory)
        case other(any AnyDNSConnectionFactory)
    }

    @usableFromInline
    let underlyingFactory: UnderlyingFactory

    @inlinable
    init(underlyingFactory: UnderlyingFactory) {
        self.underlyingFactory = underlyingFactory
    }

    @inlinable
    package static func `default`(
        configuration: DNSConnectionConfiguration,
        serverAddress: DNSServerAddress
    ) throws -> DNSConnectionFactory {
        DNSConnectionFactory(
            underlyingFactory: .default(
                try DefaultDNSConnectionFactory(
                    configuration: configuration,
                    serverAddress: serverAddress
                )
            )
        )
    }

    @inlinable
    package static func other(
        _ factory: any AnyDNSConnectionFactory
    ) -> DNSConnectionFactory {
        DNSConnectionFactory(
            underlyingFactory: .other(factory)
        )
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension DNSConnectionFactory {
    @inlinable
    package func makeUDPConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> DNSConnection {
        switch self.underlyingFactory {
        case .default(let defaultFactory):
            return try await defaultFactory.makeUDPConnection(
                address: address,
                connectionID: connectionID,
                eventLoop: eventLoop,
                logger: logger,
                isolation: isolation
            )
        case .other(let anyFactory):
            return try await anyFactory.makeUDPConnection(
                address: address,
                connectionID: connectionID,
                eventLoop: eventLoop,
                logger: logger,
                isolation: isolation
            )
        }
    }

    @inlinable
    package func makeTCPConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> DNSConnection {
        switch self.underlyingFactory {
        case .default(let defaultFactory):
            return try await defaultFactory.makeTCPConnection(
                address: address,
                connectionID: connectionID,
                eventLoop: eventLoop,
                logger: logger,
                isolation: isolation
            )
        case .other(let anyFactory):
            return try await anyFactory.makeTCPConnection(
                address: address,
                connectionID: connectionID,
                eventLoop: eventLoop,
                logger: logger,
                isolation: isolation
            )
        }
    }
}
