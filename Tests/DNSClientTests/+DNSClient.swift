import DNSClient

extension DNSClient {
    var isOverUDP: Bool {
        switch self.transport {
        case .preferUDPOrUseTCP:
            return true
        case .tcp:
            return false
        }
    }
}
