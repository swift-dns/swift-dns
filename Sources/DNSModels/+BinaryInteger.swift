extension BinaryInteger {
    /// Assumes the integer is an ASCII byte, and makes sure it is in lowercase.
    @usableFromInline
    func uncheckedASCIIToLowercase() -> Self {
        if self.isUppercasedASCIILetter {
            /// https://ss64.com/ascii.html
            /// The difference between an upper and lower cased ASCII byte is their sixth bit.
            /// Turn the sixth bit on to ensure lowercased ASCII byte.
            return self | 0b0010_0000
        } else {
            return self
        }
    }

    @usableFromInline
    var isUppercasedASCIILetter: Bool {
        self >= 0x41 && self <= 0x5A
    }
}
