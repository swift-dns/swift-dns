import DNSCore
package import Endpoint

import struct NIOCore.ByteBuffer
package import struct NIOFileSystem.ByteCount
package import struct NIOFileSystem.FilePath
package import struct NIOFileSystem.FileSystem

@available(swiftDNSApplePlatforms 15, *)
package struct HostsFile: Sendable, Hashable {
    package struct Target: Sendable, Hashable {
        package var address: AnyIPAddress
        package var zoneID: String?

        package init(
            address: AnyIPAddress,
            zoneID: String?
        ) {
            self.address = address
            self.zoneID = zoneID
        }
    }

    /// A lookup table from domain name to target.
    /// All domain names have FQDN set to false.
    package var _entries: [DomainName: Target]

    package init(_entries: [DomainName: Target]) {
        self._entries = _entries
    }

    package func target(for domainName: DomainName) -> Target? {
        if let target = self._entries[domainName] {
            return target
        }
        if domainName.isFQDN {
            var domainName = domainName
            domainName.isFQDN = false
            return self._entries[domainName]
        }
        return nil
    }

    package init(
        readingFileAt path: FilePath,
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

    init(span: Span<UInt8>) {
        self._entries = [:]

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
                Self.parseLine(
                    startIndex: chunkStartIndex,
                    endIndex: idx,
                    from: span,
                    into: &self._entries
                )

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
                Self.parseLine(
                    startIndex: chunkStartIndex,
                    endIndex: idx,
                    from: span,
                    into: &self._entries
                )

                chunkStartIndex = idx &+ 1
                idx &+== 1
            default:
                idx &+== 1
                continue
            }
        }

        Self.parseLine(
            startIndex: chunkStartIndex,
            endIndex: idx,
            from: span,
            into: &self._entries
        )
    }

    @inlinable
    static func parseLine(
        startIndex: Int,
        endIndex: Int,
        from span: Span<UInt8>,
        into entries: inout [DomainName: Target]
    ) {
        let range = Range(uncheckedBounds: (startIndex, endIndex))
        let span = span.extracting(unchecked: range)
        /// Short-circuit comment parsing
        /// No need to try to parse if the line starts with a hashtag
        if span[unchecked: 0] == .asciiHashtag {
            return
        }
        Self.parseLine(
            lineBytes: span,
            into: &entries
        )
    }

    @inlinable
    static func parseLine(
        lineBytes span: Span<UInt8>,
        into entries: inout [DomainName: Target]
    ) {
        var target: Target? = nil

        var idx = 0
        var chunkStartIndex: Int? = nil
        var previousWasSpace = false
        loop: while idx < span.count {
            /// Unchecked because idx is always in 0..<span.count
            switch span[unchecked: idx] {
            case UInt8.asciiWhitespace, UInt8.asciiTab:
                switch previousWasSpace {
                case true:
                    idx &+== 1
                    chunkStartIndex = chunkStartIndex.map { $0 &+ 1 } ?? idx
                    continue
                case false:
                    guard
                        let chunkStartIndex,
                        chunkStartIndex < idx
                    else {
                        idx &+== 1
                        chunkStartIndex = idx
                        previousWasSpace = true
                        continue
                    }

                    let chunkRange = Range(uncheckedBounds: (chunkStartIndex, idx))
                    let chunk = span.extracting(unchecked: chunkRange)

                    if let target {
                        guard
                            let domainName = try? DomainName(_uncheckedAssumingValidUTF8: chunk)
                        else {
                            /// Don't halt
                            /// TODO: maybe report the failure somehow?
                            continue
                        }
                        entries[domainName] = target
                    } else {
                        target = Target(from: chunk)
                        guard
                            /// Target must have been successfully parsed
                            let target,
                            /// Skip broadcast addresses (255.255.255.255)
                            target.address.ipv4Value?.address != .max
                        else {
                            return
                        }
                    }
                }

                chunkStartIndex = idx &+ 1
                idx &+== 1
                previousWasSpace = true
            case UInt8.asciiHashtag:
                break loop
            default:
                if chunkStartIndex == nil {
                    chunkStartIndex = idx
                }
                idx &+== 1
                previousWasSpace = false
            }
        }

        if let chunkStartIndex,
            chunkStartIndex < idx
        {
            let chunkRange = Range(uncheckedBounds: (chunkStartIndex, idx))
            let chunk = span.extracting(unchecked: chunkRange)

            if let target {
                guard let domainName = try? DomainName(_uncheckedAssumingValidUTF8: chunk) else {
                    return
                }
                entries[domainName] = target
            } else {
                /// Parsing the target here isn't of any use
                return
            }
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension HostsFile.Target {
    @inlinable
    package init?(from span: Span<UInt8>) {
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
            guard let ipAddress = AnyIPAddress(_uncheckedAssumingValidUTF8: ipAddressSpan) else {
                return nil
            }

            let zoneIDStartIndex = percentSignIndex + 1
            guard zoneIDStartIndex <= endIndex else {
                self.init(address: ipAddress, zoneID: nil)
                return
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

            self.init(address: ipAddress, zoneID: zoneID)
        case .none:
            guard let ipAddress = AnyIPAddress(_uncheckedAssumingValidUTF8: span) else {
                return nil
            }
            self.init(address: ipAddress, zoneID: nil)
        }
    }
}

// MARK: - CustomStringConvertible

@available(swiftDNSApplePlatforms 15, *)
extension HostsFile.Target: CustomStringConvertible {
    package var description: String {
        let addressString =
            switch self.address {
            case .v4(let ipv4):
                ipv4.description
            case .v6(let ipv6):
                ipv6.description
            }
        if let zoneID = self.zoneID {
            return addressString + "%" + zoneID
        }

        return addressString
    }
}
