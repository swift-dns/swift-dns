extension String {
    package var lengthInDNSWireProtocol: Int {
        self.utf8.count + 1  // +1 for the length byte
    }

    var nfcCodePoints: [UInt8] {
        var codePoints = [UInt8]()
        codePoints.reserveCapacity(self.utf8.count)
        self._withNFCCodeUnits {
            codePoints.append($0)
        }
        return codePoints
    }

    var asNFC: String {
        String(
            decoding: self.nfcCodePoints,
            as: UTF8.self
        )
    }
}
