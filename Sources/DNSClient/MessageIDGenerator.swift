import Collections

package struct MessageIDGenerator: ~Copyable {
    package enum Errors: Error {
        case overloaded
    }

    var ids: BitSet
    var count: Int

    /// Only half the UInt16 namespace is allowed.
    /// More than that it starts to get slow to generate unique IDs.
    static var maxAllowed: Int {
        32768
    }

    package init() {
        self.ids = BitSet()
        self.ids.reserveCapacity(Int(UInt16.max))
        self.count = 0
    }

    @inlinable
    package mutating func next() throws(Errors) -> UInt16 {
        if self.count == Self.maxAllowed {
            throw Errors.overloaded
        }

        let random = UInt16.random(in: 0...UInt16.max)
        let int = Int(random)
        switch ids.contains(int) {
        case true:
            /// `unsafelyUnwrapped` is safe here, there are extensive tests for this.
            /// If the value evaluates to `nil`, that would mean we've exhausted the UInt16 namespace
            /// but that cannot happen with the `Self.maxAllowed` limit imposed above.
            let next = (self.firstGreaterThan(int) ?? self.firstLessThan(int)).unsafelyUnwrapped
            ids.insert(next)
            count += 1
            /// Will be in UInt16 range, there are exhaustive tests for this
            return UInt16(next)
        case false:
            ids.insert(int)
            count += 1
            return random
        }
    }

    @inlinable
    package mutating func remove(_ id: UInt16) {
        switch ids.remove(Int(id)) {
        case .some:
            count -= 1
        case .none:
            break
        }
    }

    private func firstGreaterThan(_ id: Int) -> Int? {
        guard id < Int(UInt16.max) else { return nil }
        for newId in (id + 1)...Int(UInt16.max) {
            if !self.ids.contains(newId) {
                return newId
            }
        }
        return nil
    }

    private func firstLessThan(_ id: Int) -> Int? {
        guard id > 0 else { return nil }
        for newId in 0..<id {
            if !self.ids.contains(newId) {
                return newId
            }
        }
        return nil
    }
}
