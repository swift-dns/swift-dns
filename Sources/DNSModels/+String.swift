extension String {
    package var lengthInDNSWireProtocol: Int {
        self.utf8.count + 1  // +1 for the length byte
    }
}
