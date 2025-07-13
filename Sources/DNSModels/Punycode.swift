/// [Punycode: A Bootstring encoding of Unicode for Internationalized Domain Names in Applications (IDNA)](https://datatracker.ietf.org/doc/html/rfc3492)
enum Punycode {
    /// [Punycode: A Bootstring encoding of Unicode for IDNA: Parameter values for Punycode](https://datatracker.ietf.org/doc/html/rfc3492#section-5)
    enum Constants {
        @usableFromInline
        static var base: Int {
            36
        }

        @usableFromInline
        static var tMin: Int {
            1
        }

        @usableFromInline
        static var tMax: Int {
            26
        }

        @usableFromInline
        static var skew: Int {
            38
        }

        @usableFromInline
        static var damp: Int {
            700
        }

        @usableFromInline
        static var initialBias: Int {
            72
        }

        @usableFromInline
        static var initialN: Int {
            128
        }

        /// [Punycode: A Bootstring encoding of Unicode for IDNA: Parameter values for Punycode](https://datatracker.ietf.org/doc/html/rfc3492#section-5)
        /// 0-25 -> a-z; 26-35 -> 0-9
        @usableFromInline
        static let digitToUnicodeScalarLookupTable: [Int: UnicodeScalar] = [
            0: UnicodeScalar(0x61),
            1: UnicodeScalar(0x62),
            2: UnicodeScalar(0x63),
            3: UnicodeScalar(0x64),
            4: UnicodeScalar(0x65),
            5: UnicodeScalar(0x66),
            6: UnicodeScalar(0x67),
            7: UnicodeScalar(0x68),
            8: UnicodeScalar(0x69),
            9: UnicodeScalar(0x6a),
            10: UnicodeScalar(0x6b),
            11: UnicodeScalar(0x6c),
            12: UnicodeScalar(0x6d),
            13: UnicodeScalar(0x6e),
            14: UnicodeScalar(0x6f),
            15: UnicodeScalar(0x70),
            16: UnicodeScalar(0x71),
            17: UnicodeScalar(0x72),
            18: UnicodeScalar(0x73),
            19: UnicodeScalar(0x74),
            20: UnicodeScalar(0x75),
            21: UnicodeScalar(0x76),
            22: UnicodeScalar(0x77),
            23: UnicodeScalar(0x78),
            24: UnicodeScalar(0x79),
            25: UnicodeScalar(0x7a),
            26: UnicodeScalar(0x30),
            27: UnicodeScalar(0x31),
            28: UnicodeScalar(0x32),
            29: UnicodeScalar(0x33),
            30: UnicodeScalar(0x34),
            31: UnicodeScalar(0x35),
            32: UnicodeScalar(0x36),
            33: UnicodeScalar(0x37),
            34: UnicodeScalar(0x38),
            35: UnicodeScalar(0x39),
        ]

        /// [Punycode: A Bootstring encoding of Unicode for IDNA: Parameter values for Punycode](https://datatracker.ietf.org/doc/html/rfc3492#section-5)
        /// A-Z -> 0-25; a-z -> 0-25; 0-9 -> 26-35
        @usableFromInline
        static let unicodeScalarToDigitLookupTable: [UnicodeScalar: Int] = [
            UnicodeScalar(0x41): 0,
            UnicodeScalar(0x42): 1,
            UnicodeScalar(0x43): 2,
            UnicodeScalar(0x44): 3,
            UnicodeScalar(0x45): 4,
            UnicodeScalar(0x46): 5,
            UnicodeScalar(0x47): 6,
            UnicodeScalar(0x48): 7,
            UnicodeScalar(0x49): 8,
            UnicodeScalar(0x4a): 9,
            UnicodeScalar(0x4b): 10,
            UnicodeScalar(0x4c): 11,
            UnicodeScalar(0x4d): 12,
            UnicodeScalar(0x4e): 13,
            UnicodeScalar(0x4f): 14,
            UnicodeScalar(0x50): 15,
            UnicodeScalar(0x51): 16,
            UnicodeScalar(0x52): 17,
            UnicodeScalar(0x53): 18,
            UnicodeScalar(0x54): 19,
            UnicodeScalar(0x55): 20,
            UnicodeScalar(0x56): 21,
            UnicodeScalar(0x57): 22,
            UnicodeScalar(0x58): 23,
            UnicodeScalar(0x59): 24,
            UnicodeScalar(0x5a): 25,
            UnicodeScalar(0x61): 0,
            UnicodeScalar(0x62): 1,
            UnicodeScalar(0x63): 2,
            UnicodeScalar(0x64): 3,
            UnicodeScalar(0x65): 4,
            UnicodeScalar(0x66): 5,
            UnicodeScalar(0x67): 6,
            UnicodeScalar(0x68): 7,
            UnicodeScalar(0x69): 8,
            UnicodeScalar(0x6a): 9,
            UnicodeScalar(0x6b): 10,
            UnicodeScalar(0x6c): 11,
            UnicodeScalar(0x6d): 12,
            UnicodeScalar(0x6e): 13,
            UnicodeScalar(0x6f): 14,
            UnicodeScalar(0x70): 15,
            UnicodeScalar(0x71): 16,
            UnicodeScalar(0x72): 17,
            UnicodeScalar(0x73): 18,
            UnicodeScalar(0x74): 19,
            UnicodeScalar(0x75): 20,
            UnicodeScalar(0x76): 21,
            UnicodeScalar(0x77): 22,
            UnicodeScalar(0x78): 23,
            UnicodeScalar(0x79): 24,
            UnicodeScalar(0x7a): 25,
            UnicodeScalar(0x30): 26,
            UnicodeScalar(0x31): 27,
            UnicodeScalar(0x32): 28,
            UnicodeScalar(0x33): 29,
            UnicodeScalar(0x34): 30,
            UnicodeScalar(0x35): 31,
            UnicodeScalar(0x36): 32,
            UnicodeScalar(0x37): 33,
            UnicodeScalar(0x38): 34,
            UnicodeScalar(0x39): 35,
        ]
    }

    /// [Punycode: A Bootstring encoding of Unicode for IDNA: Encoding procedure](https://datatracker.ietf.org/doc/html/rfc3492#section-6.3)
    /// Returns true if successful and false if conversion failed.
    ///
    /// This function does not do overflow handling because based on RFC 3492,
    /// overflows are not possible for what matches the description of Swift's `UnicodeScalar` type:
    ///
    /// https://datatracker.ietf.org/doc/html/rfc3492#section-5:
    /// ```text
    /// Although the only restriction Punycode imposes on the input integers
    /// is that they be nonnegative, these parameters are especially designed
    /// to work well with Unicode [UNICODE] code points, which are integers
    /// in the range 0..10FFFF (but not D800..DFFF, which are reserved for
    /// use by the UTF-16 encoding of Unicode).
    /// ```
    ///
    /// https://datatracker.ietf.org/doc/html/rfc3492#section-6.4
    /// ```text
    /// For IDNA, 26-bit unsigned integers are sufficient to handle all valid
    /// IDNA labels without overflow, because any string that needed a 27-bit
    /// delta would have to exceed either the code point limit (0..10FFFF) or
    /// the label length limit (63 characters).  However, overflow handling
    /// is necessary because the inputs are not necessarily valid IDNA
    /// labels.
    /// ```
    @usableFromInline
    static func encode(_ input: inout Substring) -> Bool {
        var n = Constants.initialN
        var delta = 0
        var bias = Constants.initialBias
        var output = input.unicodeScalars.filter(\.isASCII)
        let b = output.count
        var h = b
        if !output.isEmpty {
            output.append(UnicodeScalar.asciiHyphenMinus)
        }
        /// FIXME: reserve extra capacity in output

        if input.unicodeScalars.contains(where: { !$0.isASCII && $0.value < n }) {
            return false
        }

        while h < input.unicodeScalars.count {
            let m = Int(
                /// FIXME: Is the force unwrap safe?
                input.unicodeScalars.lazy.filter {
                    !$0.isASCII && $0.value >= n
                }.min()!.value
            )

            delta = delta &+ ((m &- n) &* (h &+ 1))

            n = m
            for codePoint in input.unicodeScalars {
                if codePoint.value < n || codePoint.isASCII {
                    delta += 1
                }

                if codePoint.value == n {
                    var q = delta
                    for k in stride(from: Constants.base, to: .max, by: Constants.base) {
                        let t =
                            if k <= (bias &+ Constants.tMin) {
                                Constants.tMin
                            } else if k >= (bias &+ Constants.tMax) {
                                Constants.tMax
                            } else {
                                k &- bias
                            }

                        if q < t {
                            break
                        }

                        let digit = t &+ ((q &- t) % (Constants.base &- t))
                        /// Logically this is safe because we know that digit is in the range 0...35
                        /// There are also extensive tests for this in the IDNATests.swift.
                        output.append(
                            Constants.digitToUnicodeScalarLookupTable[digit].unsafelyUnwrapped
                        )
                        q = (q &- t) / (Constants.base &- t)
                    }
                    /// Logically this is safe because we know that digit is in the range 0...35
                    /// There are also extensive tests for this in the IDNATests.swift.
                    output.append(Constants.digitToUnicodeScalarLookupTable[q].unsafelyUnwrapped)

                    bias = adapt(delta: delta, codePointCount: h &+ 1, isFirstTime: h == b)
                    delta = 0
                    h += 1
                }
            }
            delta += 1
            n += 1
        }

        input = Substring(Substring.UnicodeScalarView(output))

        return true
    }

    /// [Punycode: A Bootstring encoding of Unicode for IDNA: Decoding procedure](https://datatracker.ietf.org/doc/html/rfc3492#section-6.2)
    /// Returns true if successful and false if conversion failed.
    ///
    /// This function does not do overflow handling because based on RFC 3492,
    /// overflows are not possible for what matches the description of Swift's `UnicodeScalar` type:
    ///
    /// https://datatracker.ietf.org/doc/html/rfc3492#section-5:
    /// ```text
    /// Although the only restriction Punycode imposes on the input integers
    /// is that they be nonnegative, these parameters are especially designed
    /// to work well with Unicode [UNICODE] code points, which are integers
    /// in the range 0..10FFFF (but not D800..DFFF, which are reserved for
    /// use by the UTF-16 encoding of Unicode).
    /// ```
    ///
    /// https://datatracker.ietf.org/doc/html/rfc3492#section-6.4
    /// ```text
    /// For IDNA, 26-bit unsigned integers are sufficient to handle all valid
    /// IDNA labels without overflow, because any string that needed a 27-bit
    /// delta would have to exceed either the code point limit (0..10FFFF) or
    /// the label length limit (63 characters).  However, overflow handling
    /// is necessary because the inputs are not necessarily valid IDNA
    /// labels.
    /// ```
    @usableFromInline
    static func decode(_ input: inout Substring) -> Bool {
        var n = Constants.initialN
        var i = 0
        var bias = Constants.initialBias
        var output: [UnicodeScalar]

        if let idx = input.unicodeScalars.lastIndex(of: UnicodeScalar.asciiHyphenMinus) {
            let afterDelimiterIdx = input.index(after: idx)
            output = Array(input.unicodeScalars[..<idx])
            guard output.allSatisfy(\.isASCII) else {
                return false
            }
            input = Substring(
                Substring.UnicodeScalarView(
                    input.unicodeScalars[afterDelimiterIdx...]
                )
            )
        } else {
            output = []
        }
        /// FIXME: reserve extra capacity in output

        while !input.unicodeScalars.isEmpty {
            let oldi = i
            var w = 1
            for k in stride(from: Constants.base, to: .max, by: Constants.base) {
                /// Above we check that input is not empty, so this is safe.
                /// There are also extensive tests for this in the IDNATests.swift.
                guard let codePoint = input.unicodeScalars.first else {
                    return false
                }
                input = Substring(input.unicodeScalars.dropFirst())
                guard let digit = Constants.unicodeScalarToDigitLookupTable[codePoint] else {
                    return false
                }

                i = i &+ (digit &* w)

                let t =
                    if k <= (bias &+ Constants.tMin) {
                        Constants.tMin
                    } else if k >= (bias &+ Constants.tMax) {
                        Constants.tMax
                    } else {
                        k &- bias
                    }

                if digit < t {
                    break
                }

                w = w &* (Constants.base &- t)
            }
            let outputCountPlusOne = output.count &+ 1
            bias = adapt(
                delta: i &- oldi,
                codePointCount: outputCountPlusOne,
                isFirstTime: oldi == 0
            )
            n = n &+ (i / outputCountPlusOne)
            i = i % outputCountPlusOne
            /// Check if n is basic (aka ASCII).
            if n < 128 {
                return false
            }

            guard let newUnicodeScalar = UnicodeScalar(n) else {
                return false
            }
            output.insert(newUnicodeScalar, at: i)

            i += 1
        }

        input = Substring(Substring.UnicodeScalarView(output))

        return true
    }

    /// [Punycode: A Bootstring encoding of Unicode for IDNA: Bias adaptation function](https://datatracker.ietf.org/doc/html/rfc3492#section-6.1)
    @usableFromInline
    static func adapt(delta: Int, codePointCount: Int, isFirstTime: Bool) -> Int {
        var delta =
            if isFirstTime {
                delta / Constants.damp
            } else {
                delta / 2
            }
        delta = delta &+ (delta / codePointCount)
        var k = 0
        while delta > (((Constants.base &- Constants.tMin) &* Constants.tMax) / 2) {
            delta = delta / (Constants.base &- Constants.tMin)
            k = k &+ Constants.base
        }
        return k &+ (((Constants.base &- Constants.tMin &+ 1) &* delta) / (delta &+ Constants.skew))
    }
}
