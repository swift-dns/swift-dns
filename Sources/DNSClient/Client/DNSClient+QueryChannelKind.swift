@available(swiftDNSApplePlatforms 26, *)
extension DNSClient {
    public enum QueryChannelKind: Sendable, CaseIterable {
        case udp
        case tcp
    }
}
