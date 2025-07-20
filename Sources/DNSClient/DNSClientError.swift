/// CustomStringConvertible and all
public enum DNSClientError: Error {
    case cancelled
    case connectionClosing
    case connectionClosed
    case unsolicitedResponse
    case queryTimeout
}
