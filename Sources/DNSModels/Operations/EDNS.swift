/// Edns implements the higher level concepts for working with extended dns as it is used to create or be
/// created from OPT record data.
@available(swiftDNSApplePlatforms 15, *)
public struct EDNS: Sendable {
    /// EDNS flags
    ///
    /// <https://www.rfc-editor.org/rfc/rfc6891#section-6.1.4>
    public struct Flags: Sendable {
        /// DNSSEC OK bit as defined by RFC 3225
        public var dnssecOk: Bool
        /// Remaining bits in the flags field
        ///
        /// Note that the most significant bit in this value is represented by the `dnssec_ok` field.
        /// As such, it will be zero when decoding and will not be encoded.
        ///
        /// Unless you have a specific need to set this value, we recommend leaving this as zero.
        public var z: UInt16

        var rawValue: UInt16 {
            switch self.dnssecOk {
            case true:
                return 0x8000 | self.z
            case false:
                return 0x7FFF & self.z
            }
        }

        public init(dnssecOk: Bool, z: UInt16) {
            self.dnssecOk = dnssecOk
            self.z = z
        }
    }

    // high 8 bits that make up the 12 bit total field when included with the 4bit rcode from the
    // header (from TTL)
    public var rcodeHigh: UInt8
    // Indicates the implementation level of the setter. (from TTL)
    public var version: UInt8
    public var flags: Flags
    // max payload size, minimum of 512, (from RR CLASS)
    public var maxPayload: UInt16
    public var options: OPT

    var ttl: UInt32 {
        (UInt32(self.rcodeHigh) &<< 24)
            | (UInt32(self.version) &<< 16)
            | UInt32(self.flags.rawValue)
    }

    public init(rcodeHigh: UInt8, version: UInt8, flags: Flags, maxPayload: UInt16, options: OPT) {
        self.rcodeHigh = rcodeHigh
        self.version = version
        self.flags = flags
        self.maxPayload = maxPayload
        self.options = options
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension EDNS {
    package init(fromOPTRecord record: consuming Record) {
        assert(record.rdata.recordType == .OPT)
        self.rcodeHigh = UInt8(truncatingIfNeeded: (record.ttl & 0xFF00_0000) >> 24)
        self.version = UInt8(truncatingIfNeeded: (record.ttl & 0x00FF_0000) >> 16)
        self.flags = Flags(from: record.ttl)
        self.maxPayload = record.dnsClass.rawValue
        self.options = OPT(fromOPTRData: record.rdata)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension EDNS {
    package func toRecord() -> Record {
        Record(
            nameLabels: DomainName.root,
            dnsClass: DNSClass(forOPT: self.maxPayload),
            ttl: self.ttl,
            rdata: RData.OPT(self.options)
        )
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension EDNS.Flags {
    package init(from ttl: UInt32) {
        let first16bits = UInt16(truncatingIfNeeded: ttl & 0x0000_FFFF)
        self.dnssecOk = (first16bits & 0x8000) == 0x8000
        self.z = first16bits & 0x7FFF
    }
}
