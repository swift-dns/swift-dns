import Logging
import _DNSConnectionPool

/// DNS client connection pool metrics
@available(swiftDNSApplePlatforms 26.0, *)
final class DNSClientMetrics: ConnectionPoolObservabilityDelegate {
    typealias ConnectionID = DNSConnection.ID

    let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func startedConnecting(id: ConnectionID) {
        self.logger.debug(
            "Creating new connection",
            metadata: [
                "dns_connection_id": "\(id)"
            ]
        )
    }

    /// A connection attempt failed with the given error. After some period of
    /// time ``startedConnecting(id:)`` may be called again.
    func connectFailed(id: ConnectionID, error: any Error) {
        self.logger.debug(
            "Connection creation failed",
            metadata: [
                "dns_connection_id": "\(id)",
                "error": "\(String(reflecting: error))",
            ]
        )
    }

    func connectSucceeded(id: ConnectionID) {
        self.logger.debug(
            "Connection established",
            metadata: [
                "dns_connection_id": "\(id)"
            ]
        )
    }

    /// The utlization of the connection changed; a stream may have been used, returned or the
    /// maximum number of concurrent streams available on the connection changed.
    func connectionLeased(id: ConnectionID) {
        self.logger.debug(
            "Connection leased",
            metadata: [
                "dns_connection_id": "\(id)"
            ]
        )
    }

    func connectionReleased(id: ConnectionID) {
        self.logger.debug(
            "Connection released",
            metadata: [
                "dns_connection_id": "\(id)"
            ]
        )
    }

    func keepAliveTriggered(id: ConnectionID) {
        self.logger.debug(
            "run ping pong",
            metadata: [
                "dns_connection_id": "\(id)"
            ]
        )
    }

    func keepAliveSucceeded(id: ConnectionID) {}

    func keepAliveFailed(id: DNSConnection.ID, error: any Error) {}

    /// The remote peer is quiescing the connection: no new streams will be created on it. The
    /// connection will eventually be closed and removed from the pool.
    func connectionClosing(id: ConnectionID) {
        self.logger.debug(
            "Close connection",
            metadata: [
                "dns_connection_id": "\(id)"
            ]
        )
    }

    /// The connection was closed. The connection may be established again in the future (notified
    /// via ``startedConnecting(id:)``).
    func connectionClosed(id: ConnectionID, error: (any Error)?) {
        self.logger.debug(
            "Connection closed",
            metadata: [
                "dns_connection_id": "\(id)"
            ]
        )
    }

    func requestQueueDepthChanged(_ newDepth: Int) {

    }

    func connectSucceeded(id: DNSConnection.ID, streamCapacity: UInt16) {

    }

    func connectionUtilizationChanged(
        id: DNSConnection.ID,
        streamsUsed: UInt16,
        streamCapacity: UInt16
    ) {

    }
}
