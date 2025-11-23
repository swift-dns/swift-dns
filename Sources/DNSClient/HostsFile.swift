import DNSCore
package import Endpoint

package import struct NIOCore.ByteBuffer
package import struct NIOFileSystem.ByteCount
package import struct NIOFileSystem.FilePath
package import struct NIOFileSystem.FileSystem

@available(swiftDNSApplePlatforms 13, *)
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
    /// [DomainName._data: Target]
    package var _entries: [ByteBuffer: Target]

    /// [DomainName._data: Target]
    package init(_entries: [ByteBuffer: Target]) {
        self._entries = _entries
    }

    package func target(for domainName: DomainName) -> Target? {
        self._entries[domainName._data]
    }

    /// A description
    /// - Parameters:
    ///   - path: The path to the file to read.
    ///   - fileSystem: The file system to read the file from.
    ///   - readChunkSize: The amount of bytes to read at a time from the file. Defaults to 128 KiB.
    package init(
        readingFileAt path: FilePath,
        fileSystem: FileSystem = .shared,
        readChunkSize: ByteCount = .kibibytes(128)
    ) async throws {
        self.init(_entries: [:])

        try await fileSystem.withFileHandle(
            forReadingAt: path,
            options: .init(followSymbolicLinks: true, closeOnExec: true)
        ) { fileHandle in
            var reader = fileHandle.bufferedReader(capacity: readChunkSize)
            while true {
                let (buffer, eof) = try await reader.read(while: {
                    !($0 == .asciiLineFeed || $0 == .asciiCarriageReturn)
                })
                buffer.withUnsafeReadableBytes { ptr in
                    ptr.withMemoryRebound(to: UInt8.self) {
                        self.readLine($0.span)
                    }
                }
                if eof { break }
                try await reader.drop(1)
            }
        }
    }

    @inlinable
    mutating func readLine(_ span: Span<UInt8>) {
        debugOnly {
            if span.contains(where: {
                $0 == .asciiLineFeed || $0 == .asciiCarriageReturn
            }) {
                fatalError(
                    """
                    A line that contains a line feed or carriage return is more than just a line.
                    Line: \(String(_uncheckedAssumingValidUTF8: span).debugDescription)
                    """
                )
            }
        }

        guard
            span.count > 0,
            span[unchecked: 0] != .asciiHashtag
        else {
            return
        }

        var span = span

        /// Drop `\n`. This is useful if the line is terminated with a `\r\n`.
        /// The line will be sent to this function when `\r` is seen, so we have to drop the `\n` here.
        ///
        /// We checked above the span is not empty so the index is safe and the range are safe.
        if span[unchecked: 0] == .asciiLineFeed {
            let range = Range<Int>(uncheckedBounds: (1, span.count))
            span = span.extracting(unchecked: range)
        }

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
                        self._entries[domainName._data] = target
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
                self._entries[domainName._data] = target
            } else {
                /// Parsing the target here isn't of any use
                return
            }
        }
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension HostsFile.Target {
    @inlinable
    package init?(from span: Span<UInt8>) {
        var percentSignIndex: Int? = nil
        let count = span.count
        let endIndex = count &-- 1
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
                    /// Unchecked because this can't be higher than byte buffer's writer index + 1
                    upper: count
                )
            )
            let zoneIDBuffer = span.extracting(unchecked: zoneIDRange)
            let zoneID = String(_uncheckedAssumingValidUTF8: zoneIDBuffer)

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

@available(swiftDNSApplePlatforms 13, *)
extension HostsFile: CustomStringConvertible {
    package var description: String {
        let toReserve = self._entries.reduce(into: 0) { sum, element in
            let (buffer, target) = (element.key, element.value)
            /// Domain name length
            sum += buffer.readableBytes &- 1
            /// IP address max length is 15
            sum += 13
            /// Zone ID approx length
            sum += target.zoneID == nil ? 0 : 4
        }
        var result = ""
        result.reserveCapacity(toReserve &+ "HostsFile(_entries: [])".count)

        result += "HostsFile(_entries: ["

        var iterator = self._entries.makeIterator()
        if let (buffer, target) = iterator.next() {
            let domainName = DomainName(
                isFQDN: false,
                _uncheckedAssumingValidWireFormatBytes: buffer
            )
            result += "\(domainName): \(target)"
        }
        while let (buffer, target) = iterator.next() {
            let domainName = DomainName(
                isFQDN: false,
                _uncheckedAssumingValidWireFormatBytes: buffer
            )
            result += ", \(domainName): \(target)"
        }

        result += "])"
        return result
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension HostsFile.Target: CustomStringConvertible {
    package var description: String {
        let addressString = self.address.description
        if let zoneID = self.zoneID {
            return addressString + "%" + zoneID
        }
        return addressString
    }
}
