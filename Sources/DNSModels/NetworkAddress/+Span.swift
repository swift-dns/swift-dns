@available(swiftDNSApplePlatforms 13, *)
extension Span {
    @inlinable
    func firstIndex(
        where predicate: (Element) -> Bool
    ) -> Int? where Element: Equatable {
        for idx in self.indices {
            if predicate(self[unchecked: idx]) {
                return idx
            }
        }
        return nil
    }
}
