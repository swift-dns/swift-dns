/// FIXME
/// TODO: use with typed throws?
/// TODO: take function and line?
@usableFromInline
@available(swiftDNSApplePlatforms 10.15, *)
package enum ProtocolError: Error {
    case lengthLimitExceeded(StaticString, actual: Int, max: Int, DNSBuffer)
    case operationUnsupported(StaticString, DNSBuffer)
    case badHeader(DNSBuffer)
    case failedToRead(StaticString, DNSBuffer)
    case failedToValidate(StaticString, DNSBuffer)
    case badCharacter(in: StaticString, character: UInt8, DNSBuffer)
}
