import DNSClient
import ServiceLifecycle

@available(SwiftStdlib 5.1, *)
typealias DNSClientService = _DNSClientProtocol & Sendable & Service
