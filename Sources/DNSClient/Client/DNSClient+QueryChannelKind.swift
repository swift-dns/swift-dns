extension DNSClient {
    public enum QueryChannelKind: Sendable, CaseIterable {
        case udp
        case tcp
    }
}
