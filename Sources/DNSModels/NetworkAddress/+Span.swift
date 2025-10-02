public import DNSCore

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

    @inlinable
    func lastIndex(
        where predicate: (Element) -> Bool
    ) -> Int? where Element: Equatable {
        if self.isEmpty { return nil }
        let lastIdx = self.count &-- 1
        for idx in self.indices {
            let backwardsIdx = lastIdx &-- idx
            if predicate(self[unchecked: backwardsIdx]) {
                return backwardsIdx
            }
        }
        return nil
    }
}
