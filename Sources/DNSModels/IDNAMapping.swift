package enum IDNAMapping: Equatable {
    package enum IDNA2008Status {
        case NV8
        case XV8
        case none
    }

    case valid(IDNA2008Status)
    case mapped([UnicodeScalar])
    case deviation([UnicodeScalar])
    case disallowed
    case ignored
}
