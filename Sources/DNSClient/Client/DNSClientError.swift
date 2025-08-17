/// CustomStringConvertible and all
public enum DNSClientError: Error {
    case cancelled
    case connectionClosing
    case connectionClosed
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

extension DNSClientError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cancelled:
            return "cancelled"
        case .connectionClosing:
            return "connectionClosing"
        case .connectionClosed:
            return "connectionClosed"
        case .queryTimeout:
            return "queryTimeout"
        case .connectionClosedDueToCancellation:
            return "connectionClosedDueToCancellation"
        case .handlerRemoved:
            return "handlerRemoved"
        case .channelInactive:
            return "channelInactive"
        case .decodingError(let error):
            return "decodingError(\(String(reflecting: error)))"
        case .encodingError(let error):
            return "encodingError(\(String(reflecting: error)))"
        }
    }
}
