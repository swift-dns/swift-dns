import DNSClient
import ServiceLifecycle

@available(swiftDNSApplePlatforms 10.15, *)
typealias DNSClientService = _DNSClientProtocol & Sendable & Service
