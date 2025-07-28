/// CustomStringConvertible and all
public enum DNSClientError: Error {
    case cancelled
    case connectionClosing
    case connectionClosed
    case unsolicitedResponse
    case queryTimeout
    case connectionClosedDueToCancellation
    case handlerRemoved
    case channelInactive
    case decodingError(any Error)
    case encodingError(any Error)

    var isChannelInactive: Bool {
        switch self {
        case .channelInactive:
            return true
        default:
            return false
        }
    }
}
