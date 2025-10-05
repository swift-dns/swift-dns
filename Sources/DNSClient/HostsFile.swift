import DNSCore
package import Endpoint

package import struct DNSModels.TinyFastSequence
import struct NIOCore.ByteBuffer
package import struct NIOFileSystem.ByteCount
package import struct NIOFileSystem.FilePath
package import struct NIOFileSystem.FileSystem

@available(swiftDNSApplePlatforms 15, *)
package struct HostsFile: Sendable, Hashable {
    package struct Entry: Sendable, Hashable {
        package var address: AnyIPAddress
        package var zoneID: String?
        package var host: DomainName
        package var aliases: TinyFastSequence<DomainName>

        package init(
            address: AnyIPAddress,
            zoneID: String?,
            host: DomainName,
            aliases: TinyFastSequence<DomainName>
        ) {
            self.address = address
            self.zoneID = zoneID
            self.host = host
            self.aliases = aliases
        }
    }

    package var entries: [Entry]

    package init(entries: [Entry]) {
        self.entries = entries
    }

    package init(
        withFileAt path: FilePath,
        fileSystem: FileSystem,
        maximumSizeAllowed: ByteCount,
    ) async throws {
        /// Read the whole file, hosts files are usually not huge
        let buffer = try await fileSystem.withFileHandle(
            forReadingAt: path,
            options: .init(followSymbolicLinks: true, closeOnExec: true)
        ) { fileHandle in
            try await fileHandle.readToEnd(maximumSizeAllowed: maximumSizeAllowed)
        }
        self = buffer.withUnsafeReadableBytes { ptr in
            let span = ptr.bindMemory(to: UInt8.self).span
            return Self(span: span)
        }
    }

    package init(span: Span<UInt8>) {
        self.entries = []

        guard span.count > 0 else {
            return
        }

        var idx = 0
        var chunkStartIndex = 0
        let count = span.count
        while idx < count {
            /// Unchecked because idx is always in 0..<span.count
            switch span[unchecked: idx] {
            case UInt8.asciiCarriageReturn:
                if let entry = Self.parseLine(
                    startIndex: chunkStartIndex,
                    endIndex: idx,
                    from: span
                ) {
                    entries.append(entry)
                }

                let nextIdx = idx &+ 1
                if count > nextIdx,
                    span[unchecked: nextIdx] == UInt8.asciiLineFeed
                {
                    /// This is a \r\n, skip the \n too
                    idx &+== 1
                }

                chunkStartIndex = idx &+ 1
                idx &+== 1
            case UInt8.asciiLineFeed:
                if let entry = Self.parseLine(
                    startIndex: chunkStartIndex,
                    endIndex: idx,
                    from: span
                ) {
                    entries.append(entry)
                }
                chunkStartIndex = idx &+ 1
                idx &+== 1
            default:
                idx &+== 1
                continue
            }
        }

        if let entry = Self.parseLine(
            startIndex: chunkStartIndex,
            endIndex: idx,
            from: span
        ) {
            entries.append(entry)
        }
    }

    @usableFromInline
    static func parseLine(
        startIndex: Int,
        endIndex: Int,
        from span: Span<UInt8>
    ) -> Entry? {
        let range = Range(uncheckedBounds: (startIndex, endIndex))
        let span = span.extracting(unchecked: range)
        /// Short-circuit comment parsing
        /// No need to try to parse if the line starts with a hashtag
        if span[unchecked: 0] == .asciiHashtag {
            return nil
        }
        let entry = Entry(lineBytes: span)
        return entry
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension HostsFile.Entry {
    init?(lineBytes span: Span<UInt8>) {
        var address: AnyIPAddress? = nil
        var zoneID: String? = nil
        var host: DomainName? = nil
        var aliases: TinyFastSequence<DomainName> = .init()

        var idx = 0
        var chunkStartIndex: Int? = nil
        var previousWasWhitespace = false
        while idx < span.count {
            /// Unchecked because idx is always in 0..<span.count
            switch span[unchecked: idx] {
            case UInt8.asciiWhitespace:
                switch previousWasWhitespace {
                case true:
                    idx &+== 1
                    continue
                case false:
                    guard
                        let chunkStartIndex,
                        chunkStartIndex > idx
                    else {
                        previousWasWhitespace = true
                        idx &+== 1
                        continue
                    }

                    let chunkRange = Range(uncheckedBounds: (chunkStartIndex, idx))
                    let chunk = span.extracting(unchecked: chunkRange)

                    if address == nil {
                        guard let new = Self.parseAddressAndZoneID(from: chunk) else {
                            return nil
                        }
                        address = new.0
                        zoneID = new.1
                    } else {
                        /// FIXME: remove usage of array, use span directly
                        let array = [UInt8](unsafeUninitializedCapacity: chunk.count) {
                            (arrayBuffer, arrayCount) in
                            let ptr = UnsafeMutableRawBufferPointer(arrayBuffer)
                            chunk.withUnsafeBytes { chunkPtr in
                                ptr.copyMemory(from: chunkPtr)
                            }
                            arrayCount = chunk.count
                        }
                        guard
                            let domainName = try? DomainName(expectingASCIIBytes: array)
                        else {
                            return nil
                        }
                        if host == nil {
                            host = domainName
                        } else {
                            aliases.append(domainName)
                        }
                    }

                    previousWasWhitespace = true
                }

                chunkStartIndex = idx &+ 1
                idx &+== 1
                previousWasWhitespace = true
            case UInt8.asciiHashtag:
                break
            default:
                if chunkStartIndex == nil {
                    chunkStartIndex = idx
                }
                idx &+== 1
                previousWasWhitespace = false
            }
        }

        if let chunkStartIndex,
            chunkStartIndex < idx
        {
            let chunkRange = Range(uncheckedBounds: (chunkStartIndex, idx))
            let chunk = span.extracting(unchecked: chunkRange)

            if address == nil {
                guard let new = Self.parseAddressAndZoneID(from: chunk) else {
                    return nil
                }
                address = new.0
                zoneID = new.1
            } else {
                /// FIXME: remove usage of array, use span directly
                let array = [UInt8](unsafeUninitializedCapacity: chunk.count) {
                    (arrayBuffer, arrayCount) in
                    let ptr = UnsafeMutableRawBufferPointer(arrayBuffer)
                    chunk.withUnsafeBytes { chunkPtr in
                        ptr.copyMemory(from: chunkPtr)
                    }
                    arrayCount = chunk.count
                }
                guard
                    let domainName = try? DomainName(expectingASCIIBytes: array)
                else {
                    return nil
                }
                if host == nil {
                    host = domainName
                } else {
                    aliases.append(domainName)
                }
            }
        }

        guard let address, let host else {
            return nil
        }

        self.address = address
        self.zoneID = zoneID
        self.host = host
        self.aliases = aliases
    }

    static func parseAddressAndZoneID(
        from span: Span<UInt8>
    ) -> (AnyIPAddress, String?)? {
        var percentSignIndex: Int? = nil
        let endIndex = span.count &-- 1
        for idx in span.indices {
            let backwardsIdx = endIndex &-- idx
            /// Unchecked because backwardsIdx is always in 0..<span.count
            switch span[unchecked: backwardsIdx] {
            case UInt8.asciiPercent:
                percentSignIndex = backwardsIdx
                break
            default:
                continue
            }
        }

        switch percentSignIndex {
        case .some(let percentSignIndex):
            let ipAddressRange = Range(uncheckedBounds: (0, percentSignIndex))
            let ipAddressSpan = span.extracting(unchecked: ipAddressRange)
            guard let ipAddress = AnyIPAddress(textualRepresentation: ipAddressSpan) else {
                return nil
            }

            let zoneIDStartIndex = percentSignIndex + 1
            guard zoneIDStartIndex <= endIndex else {
                return (ipAddress, nil)
            }
            let zoneIDRange = Range<Int>(
                uncheckedBounds: (
                    /// Unchecked because this can't be higher than byte buffer's writer index
                    lower: zoneIDStartIndex,
                    /// Unchecked because this can't be higher than byte buffer's writer index
                    upper: endIndex
                )
            )
            let zoneID = String(
                unsafeUninitializedCapacity: zoneIDRange.count,
                initializingUTF8With: { stringBuffer in
                    let bufferPointer = UnsafeMutableRawBufferPointer(stringBuffer)
                    span.withUnsafeBytes { spanPtr in
                        let zoneIDBuffer = UnsafeRawBufferPointer(rebasing: spanPtr[zoneIDRange])
                        bufferPointer.copyMemory(from: zoneIDBuffer)
                    }
                    return zoneIDRange.count
                }
            )

            return (ipAddress, zoneID)
        case .none:
            guard let ipAddress = AnyIPAddress(textualRepresentation: span) else {
                return nil
            }
            return (ipAddress, nil)
        }
    }
}
