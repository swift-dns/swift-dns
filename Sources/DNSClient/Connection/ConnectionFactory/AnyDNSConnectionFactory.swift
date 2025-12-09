public import Logging
public import NIOCore

@available(swiftDNSApplePlatforms 13, *)
@usableFromInline
package protocol AnyDNSConnectionFactory: Sendable {
    @inlinable
    func makeUDPConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)?
    ) async throws -> DNSConnection

    @inlinable
    func makeTCPConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)?
    ) async throws -> DNSConnection
}
