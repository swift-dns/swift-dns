extension Unicode.Scalar {
    @inlinable
    var isNumberOrLowercasedLetterOrHyphenMinusASCII: Bool {
        (self.value >= 0x30 && self.value <= 0x39)
            || (self.value >= 0x61 && self.value <= 0x7A)
            || self.isHyphenMinus
    }

    @inlinable
    var isHyphenMinus: Bool {
        self.value == 0x2D
    }

    @inlinable
    static var asciiHyphenMinus: UnicodeScalar {
        UnicodeScalar(0x2D).unsafelyUnwrapped
    }

    @inlinable
    static var asciiDot: UnicodeScalar {
        UnicodeScalar(0x2E).unsafelyUnwrapped
    }

    @inlinable
    static var asciiLowercasedX: UnicodeScalar {
        UnicodeScalar(0x78).unsafelyUnwrapped
    }

    @inlinable
    static var asciiLowercasedN: UnicodeScalar {
        UnicodeScalar(0x6E).unsafelyUnwrapped
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
