package import struct NIOCore.ByteBuffer

/// FIXME
/// TODO: use with typed throws?
/// TODO: take function and line?
package enum ProtocolError: Error {
    case lengthLimitExceeded(StaticString,actual: Int, max: Int, ByteBuffer)
    // case decodingUnsupported(StaticString, ByteBuffer)
    case operationUnsupported(StaticString, ByteBuffer)
    case badHeader(ByteBuffer)
    case failedToRead(StaticString, ByteBuffer)
    case failedToValidate(StaticString, ByteBuffer)
    // case requiresDynamicGeneration(StaticString, ByteBuffer)
    case badCharacter(in: StaticString, character: UInt8, ByteBuffer)
}
