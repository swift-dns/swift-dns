public import DNSCore

public import struct Collections.BitSet

@usableFromInline
package struct MessageIDGenerator: ~Copyable {
    @usableFromInline
    package enum Errors: Error {
        case overloaded
    }

    @usableFromInline
    var ids: BitSet
    @usableFromInline
    var count: UInt16

    /// Only 3/4 of the UInt16 namespace is allowed.
    /// More than that it starts to get slow to generate unique IDs.
    /// `MessageIDGenerator` allows you to call `remove(_:)` to reclaim ID space,
    /// so it can issue more IDs than this number. It just can't allow more than this amount of
    /// IDs to simultaneously exist at the same time without having been `remove(_:)`ed.
    @usableFromInline
    package static var capacity: Int {
        Int(UInt16.max / 4 * 3)
    }

    /// Avoid using `0` because that's used as a placeholder in other places as the message id.
    /// Using `0` wouldn't be the end of the world but it does complicate things a little bit.
    /// For example in tests we check that messageID is no longer `0` to make sure the code is
    /// indeed reassigning a proper message id. If we allow `0` here, some tests could
    /// intermittently fail, even though the chance for that would be fairly low.
    @usableFromInline
    static var randomNumberRange: ClosedRange<UInt16> {
        1...UInt16.max
    }

    package init() {
        self.ids = BitSet()
        self.ids.reserveCapacity(Int(UInt16.max))
        self.count = 0
    }

    @inlinable
    package mutating func next() throws(Errors) -> UInt16 {
        if self.count == Self.capacity {
            throw Errors.overloaded
        }

        /// Skip 0, that's what will be assigned as a placeholder by other places
        let random = UInt16.random(in: Self.randomNumberRange)
        let int = Int(random)
        switch ids.contains(int) {
        case true:
            /// `unsafelyUnwrapped` is safe here, there are extensive tests for this.
            /// If the value evaluates to `nil`, that would mean we've exhausted the UInt16 namespace
            /// but that cannot happen with the `Self.maxAllowed` limit imposed above.
            let next = (self.firstGreaterThan(int) ?? self.firstLessThan(int)).unsafelyUnwrapped
            ids.insert(next)
            count &+== 1
            /// Will be in UInt16 range, there are exhaustive tests for this
            return UInt16(next)
        case false:
            ids.insert(int)
            count &+== 1
            return random
        }
    }

    @discardableResult @inlinable
    package mutating func remove(_ id: UInt16) -> Bool {
        switch ids.remove(Int(id)) {
        case .some:
            count &-== 1
            return true
        case .none:
            return false
        }
    }

    @usableFromInline
    func firstGreaterThan(_ id: Int) -> Int? {
        guard id < Int(UInt16.max) else { return nil }
        for newId in (id &++ 1)...Int(UInt16.max) {
            if !self.ids.contains(newId) {
                return newId
            }
        }
        return nil
    }

    @usableFromInline
    func firstLessThan(_ id: Int) -> Int? {
        guard id > 0 else { return nil }
        for newId in 0..<id {
            if !self.ids.contains(newId) {
                return newId
            }
        }
        return nil
    }
}

/// `MessageIDGenerator` is actually fine being Sendable, just that I don't expect it to
/// need to be used correctly where it needs to be Sendable as well.
/// Usually it must only be owned by one channel handler and must not be shared with anyone else.
@available(*, unavailable)
extension MessageIDGenerator: Sendable {}
