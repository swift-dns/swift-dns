public import Logging
public import NIOCore

@available(swiftDNSApplePlatforms 13, *)
@usableFromInline
package struct DNSConnectionFactory: Sendable {
    @usableFromInline
    enum UnderlyingFactory: Sendable {
        case `default`(DefaultDNSConnectionFactory)
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
        case .default(let underlyingFactory):
            return try await underlyingFactory.makeUDPConnection(
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
        case .default(let underlyingFactory):
            return try await underlyingFactory.makeTCPConnection(
                address: address,
                connectionID: connectionID,
                eventLoop: eventLoop,
                logger: logger,
                isolation: isolation
            )
        }
    }
}
