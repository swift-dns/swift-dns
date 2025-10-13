@available(swiftDNSApplePlatforms 13, *)
extension Span {
    @inlinable
    package func contains(where predicate: (Element) -> Bool) -> Bool {
        for idx in self.indices {
            if predicate(self[unchecked: idx]) {
                return true
            }
        }
        return false
    }
}
