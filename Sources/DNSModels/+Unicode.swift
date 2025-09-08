extension Unicode.Scalar {
    @inlinable
    var isASCIIAlphanumeric: Bool {
        /// TODO: make sure `ClosedRange.contains` indeed has a negative performance impact.
        /// If not, just use that.
        let latin_0to9_start = 0x30
        let latin_0to9_end = 0x39
        let latin_AtoZ_start = 0x41
        let latin_AtoZ_end = 0x5A
        let latin_atoz_start = 0x61
        let latin_atoz_end = 0x7A
        return self.value >= latin_0to9_start && self.value <= latin_0to9_end
            || self.value >= latin_AtoZ_start && self.value <= latin_AtoZ_end
            || self.value >= latin_atoz_start && self.value <= latin_atoz_end
    }

    @inlinable
    static var asciiDot: Unicode.Scalar {
        "."
    }
}

extension Unicode.GeneralCategory {
    @inlinable
    var isNumeric: Bool {
        switch self {
        case .decimalNumber, .letterNumber, .otherNumber:
            return true
        default:
            return false
        }
    }
}
