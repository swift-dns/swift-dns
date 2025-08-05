public import struct Collections.OrderedSet
public import struct NIOCore.ByteBuffer

public struct RecordTypeSet: Sendable {
    public var types: OrderedSet<RecordType>
    public var originalEncoding: ByteBuffer?
}

extension RecordTypeSet {
    enum BitMapReadingState: ~Copyable {
        case window
        case len(window: UInt8)
        case recordType(window: UInt8, bitMapLength: UInt8, left: UInt8)
    }

    package init(from buffer: inout DNSBuffer) throws {
        /// 3.2.1.  Type Bit Maps Encoding
        ///
        /// The encoding of the Type Bit Maps field is the same as that used by
        /// the NSEC RR, described in [RFC4034].  It is explained and clarified
        /// here for clarity.
        ///
        /// The RR type space is split into 256 window blocks, each representing
        /// the low-order 8 bits of the 16-bit RR type space.  Each block that
        /// has at least one active RR type is encoded using a single octet
        /// window number (from 0 to 255), a single octet bitmap length (from 1
        /// to 32) indicating the number of octets used for the bitmap of the
        /// window block, and up to 32 octets (256 bits) of bitmap.
        ///
        /// Blocks are present in the NSEC3 RR RDATA in increasing numerical
        /// order.
        ///
        /// Type Bit Maps Field = ( Window Block # | Bitmap Length | Bitmap )+
        ///
        /// where "|" denotes concatenation.
        ///
        /// Each bitmap encodes the low-order 8 bits of RR types within the
        /// window block, in network bit order.  The first bit is bit 0.  For
        /// window block 0, bit 1 corresponds to RR type 1 (A), bit 2 corresponds
        /// to RR type 2 (NS), and so forth.  For window block 1, bit 1
        /// corresponds to RR type 257, bit 2 to RR type 258.  If a bit is set to
        /// 1, it indicates that an RRSet of that type is present for the
        /// original owner name of the NSEC3 RR.  If a bit is set to 0, it
        /// indicates that no RRSet of that type is present for the original
        /// owner name of the NSEC3 RR.
        ///
        /// Since bit 0 in window block 0 refers to the non-existing RR type 0,
        ///it MUST be set to 0.  After verification, the validator MUST ignore
        /// the value of bit 0 in window block 0.
        ///
        /// Bits representing Meta-TYPEs or QTYPEs as specified in Section 3.1 of
        /// [RFC2929] or within the range reserved for assignment only to QTYPEs
        /// and Meta-TYPEs MUST be set to 0, since they do not appear in zone
        /// data.  If encountered, they must be ignored upon reading.
        ///
        /// Blocks with no types present MUST NOT be included.  Trailing zero
        /// octets in the bitmap MUST be omitted.  The length of the bitmap of
        /// each block is determined by the type code with the largest numerical
        /// value, within that block, among the set of RR types present at the
        ///  original owner name of the NSEC3 RR.  Trailing octets not specified
        ///  MUST be interpreted as zero octets.
        self.originalEncoding = buffer.readToEnd()

        self.types = []

        var state: BitMapReadingState = .window

        /// Loop through all the bytes in the bitmap
        /// Just assigned a value to `originalEncoding` above, so it can't be nil
        for currentByte in self.originalEncoding!.readableBytesView {
            switch consume state {
            case .window:
                state = .len(window: currentByte)
            case let .len(window):
                state = .recordType(
                    window: window,
                    bitMapLength: currentByte,
                    left: currentByte
                )
            case let .recordType(window, bitMapLength, left):
                // Window is the Window Block # from above
                // CurrentByte is the Bitmap
                var bitMap = currentByte

                /// For all the bits in the currentByte
                for i in (0 as UInt8)..<8 {
                    /// If the currentBytes most significant bit is set
                    if bitMap & 0b1000_0000 == 0b1000_0000 {
                        /// bitMapLength - left is the block in the bitmap, times 8 for the bits, + the bit in the currentByte
                        // var lowByte = (bitMapLength - left) * 8 + i
                        var lowByte: UInt8 = bitMapLength
                        var overflew = false
                        (lowByte, overflew) = lowByte.subtractingReportingOverflow(left)
                        if overflew {
                            throw ProtocolError.failedToRead("RecordTypeSet", buffer)
                        }
                        (lowByte, overflew) = lowByte.multipliedReportingOverflow(by: 8)
                        if overflew {
                            throw ProtocolError.failedToRead("RecordTypeSet", buffer)
                        }
                        (lowByte, overflew) = lowByte.addingReportingOverflow(i)
                        if overflew {
                            throw ProtocolError.failedToRead("RecordTypeSet", buffer)
                        }
                        let rrType =
                            (UInt16(truncatingIfNeeded: window) &<< 8)
                            | UInt16(truncatingIfNeeded: lowByte)
                        types.append(RecordType(rrType))
                    }
                    // Shift left and look at the next bit
                    bitMap &<<= 1
                }

                /// Move to the next section of the bitMap
                let (left, overflew) = left.subtractingReportingOverflow(1)
                if overflew {
                    throw ProtocolError.failedToRead("RecordTypeSet", buffer)
                }
                if left == 0 {
                    /// We've exhausted this Window, move to the next
                    state = .window
                } else {
                    /// Continue reading this Window
                    state = .recordType(
                        window: window,
                        bitMapLength: bitMapLength,
                        left: left
                    )
                }
            }
        }
    }
}

extension RecordTypeSet {
    package func encode(into buffer: inout DNSBuffer) {
        if case let .some(encodedBytes) = self.originalEncoding {
            buffer.writeBuffer(encodedBytes)
            return
        }

        var hash: [UInt8: [UInt8]] = [:]

        // collect the bitmaps
        for rrType in self.types {
            let code = rrType.rawValue
            let window: UInt8 = numericCast(code >> 8)
            let low: UInt8 = numericCast(code & 0x00FF)

            var bitMap = hash[window] ?? []
            // len + left is the block in the bitmap, divided by 8 for the bits, + the bit in the currentByte
            let index: Int = numericCast(low / 8)
            let bit = (0b1000_0000 as UInt8) >> (low % 8)

            if bitMap.count < (index + 1) {
                bitMap.append(0)
            }

            bitMap[index] = bitMap[index] | bit
            hash[window] = bitMap
        }

        // output bitmaps
        for (window, bitmap) in hash {
            buffer.writeInteger(window)
            // the hashset should never be larger that 255 based on above logic.
            buffer.writeInteger(UInt8(bitmap.count))
            for bits in bitmap {
                buffer.writeInteger(bits)
            }
        }
    }
}
