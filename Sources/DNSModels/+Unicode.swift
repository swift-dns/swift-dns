extension Unicode.Scalar {
    @usableFromInline
    var isHyphen: Bool {
        self.value == 0x2D
    }

    @usableFromInline
    static var asciiDash: UnicodeScalar {
        UnicodeScalar(0x2D).unsafelyUnwrapped
    }
}

extension Unicode.GeneralCategory {
    @usableFromInline
    var isNumeric: Bool {
        switch self {
        case .decimalNumber, .letterNumber, .otherNumber:
            return true
        default:
            return false
        }
    }

    @usableFromInline
    var isMark: Bool {
        switch self {
        case .spacingMark, .enclosingMark, .nonspacingMark:
            return true
        default:
            return false
        }
    }
}
