public import SwiftIDNA

import struct NIOCore.ByteBuffer

extension DomainName {
    /// Parses and case-folds the name from the string, and ensures the name is valid.
    /// Example: try DomainName(string: "mahdibm.com")
    /// Converts the domain name to ASCII if it's not already according to the IDNA spec.
    @inlinable
    public init(
        string domainName: String,
        idnaConfiguration: IDNA.Configuration = .default
    ) throws {
        self.init()

        // short circuit root parse
        if domainName.unicodeScalars.count == 1,
            domainName.unicodeScalars.first?.isIDNALabelSeparator == true
        {
            self.isFQDN = true
            return
        }

        var domainName = domainName

        /// Remove the trailing dot if it exists, and set the FQDN flag
        /// The IDNA spec doesn't like the root label separator.
        if domainName.unicodeScalars.last?.isIDNALabelSeparator == true {
            self.isFQDN = true
            domainName = String(domainName.unicodeScalars.dropLast())
        }

        /// TODO: make sure all initializations of DomainName go through a single initializer that
        /// asserts lowercased ASCII?

        /// short-circuits most domain names which won't change with IDNA anyway.
        try IDNA(
            configuration: idnaConfiguration
        ).toASCII(
            domainName: &domainName
        )

        try Self.from(guaranteedASCIIBytes: domainName.utf8, into: &self)
    }
}

extension DomainName: CustomStringConvertible {
    /// Unicode-friendly description of the domain name, excluding the possible root label separator.
    public var description: String {
        self.description(format: .unicode)
    }
}

extension DomainName: CustomDebugStringConvertible {
    /// Byte-accurate description of the domain name.
    public var debugDescription: String {
        self.description(format: .ascii, options: .includeRootLabelIndicator)
    }
}

extension DomainName {
    /// FIXME: public nonfrozen enum
    public enum DescriptionFormat: Sendable {
        /// ASCII-only description of the domain name, as in the wire format and IDNA.
        case ascii
        /// Unicode representation of the domain name, converting IDNA names to Unicode.
        case unicode
    }

    public struct DescriptionOptions: Sendable, OptionSet {
        public var rawValue: Int

        @inlinable
        public static var includeRootLabelIndicator: Self {
            Self(rawValue: 1 << 0)
        }

        @inlinable
        public static var sourceAccurate: Self {
            .includeRootLabelIndicator
        }

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public func description(
        format: DescriptionFormat,
        options: DescriptionOptions = []
    ) -> String {
        var scalars: [Unicode.Scalar] = []
        let neededCapacity =
            options.contains(.includeRootLabelIndicator)
            ? self.encodedLength : self.encodedLength - 1
        scalars.reserveCapacity(neededCapacity)

        var iterator = self.makeIterator()
        if let (startIndex, length) = iterator.nextLabelPositionInNameData() {
            /// These are all ASCII bytes so safe to map directly
            self.data.withUnsafeReadableBytes { ptr in
                for idx in startIndex..<(startIndex + length) {
                    scalars.append(Unicode.Scalar(ptr[idx]))
                }
            }
        }

        while let (startIndex, length) = iterator.nextLabelPositionInNameData() {
            scalars.append(".")
            /// These are all ASCII bytes so safe to map directly
            self.data.withUnsafeReadableBytes { ptr in
                for idx in startIndex..<(startIndex + length) {
                    scalars.append(Unicode.Scalar(ptr[idx]))
                }
            }
        }

        var domainName = String(String.UnicodeScalarView(scalars))

        if format == .unicode {
            do {
                try IDNA(configuration: .mostLax)
                    .toUnicode(domainName: &domainName)
            } catch {
                domainName = String(String.UnicodeScalarView(scalars))
            }
        }

        if self.isFQDN,
            options.contains(.includeRootLabelIndicator)
        {
            domainName.append(".")
        }

        return domainName
    }
}
