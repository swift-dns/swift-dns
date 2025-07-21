import Collections

package struct MessageIDGenerator: ~Copyable {
    package enum Errors: Error {
        case overloaded
    }

    var ids: BitSet
    var count: Int

    package init() {
        self.ids = BitSet()
        self.ids.reserveCapacity(Int(UInt16.max))
        self.count = 0
    }

    @inlinable
    package mutating func next() throws(Errors) -> UInt16 {
        let random = UInt16.random(in: 0...UInt16.max)
        if let result = try validate(Int(random), function: self.firstGreaterThan) {
            /// Will be in UInt16 range, there are exhaustive tests for this
            return UInt16(result)
        }
        if let result = try validate(Int(random), function: self.firstLessThan) {
            /// Will be in UInt16 range, there are exhaustive tests for this
            return UInt16(result)
        }
        throw Errors.overloaded
    }

    mutating func validate(
        _ int: Int,
        function: (Int) -> Int?
    ) throws(Errors) -> Int? {
        switch ids.contains(int) {
        case true:
            if let next = function(int) {
                return try validate(next, function: function)
            } else {
                return nil
            }
        case false:
            ids.insert(int)
            count += 1
            return int
        }
    }

    @inlinable
    package mutating func removeExisting(_ id: UInt16) {
        switch ids.remove(Int(id)) {
        case .none:
            assertionFailure("ID \(id) was not found in the set \(ids)")
        case .some:
            count -= 1
        }
    }

    private func firstGreaterThan(_ id: Int) -> Int? {
        self.ids.first(where: { $0 > id })
    }

    private func firstLessThan(_ id: Int) -> Int? {
        self.ids.first(where: { $0 < id })
    }
}
