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
    var isNumberOrLowercasedLetterOrHyphenMinusASCII: Bool {
        (self.value >= 0x30 && self.value <= 0x39)
            || (self.value >= 0x61 && self.value <= 0x7A)
            || self.isHyphenMinus
    }

    @inlinable
    var isNumberOrLowercasedLetterOrDotASCII: Bool {
        (self.value >= 0x30 && self.value <= 0x39)
            || (self.value >= 0x61 && self.value <= 0x7A)
            || self.isASCIIDot
    }

    @inlinable
    var isUppercasedASCII: Bool {
        self.value >= 0x41 && self.value <= 0x5A
    }

    @inlinable
    static var asciiHyphenMinus: Unicode.Scalar {
        Unicode.Scalar(0x2D).unsafelyUnwrapped
    }

    @inlinable
    var isHyphenMinus: Bool {
        self.value == 0x2D
    }

    @inlinable
    static var asciiDot: Unicode.Scalar {
        Unicode.Scalar(0x2E).unsafelyUnwrapped
    }

    @inlinable
    var isASCIIDot: Bool {
        self.value == 0x2E
    }

    @inlinable
    static var asciiLowercasedX: Unicode.Scalar {
        Unicode.Scalar(0x78).unsafelyUnwrapped
    }

    @inlinable
    static var asciiLowercasedN: Unicode.Scalar {
        Unicode.Scalar(0x6E).unsafelyUnwrapped
    }

    /// IDNA label separators.
    /// U+002E ( . ) FULL STOP
    /// U+FF0E ( ． ) FULLWIDTH FULL STOP
    /// U+3002 ( 。 ) IDEOGRAPHIC FULL STOP
    /// U+FF61 ( ｡ ) HALFWIDTH IDEOGRAPHIC FULL STOP
    /// https://www.unicode.org/reports/tr46/#Notation
    @inlinable
    var isIDNALabelSeparator: Bool {
        self.value == 0x2E
            || self.value == 0xFF0E
            || self.value == 0x3002
            || self.value == 0xFF61
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

    @inlinable
    var isMark: Bool {
        switch self {
        case .spacingMark, .enclosingMark, .nonspacingMark:
            return true
        default:
            return false
        }
    }
}
