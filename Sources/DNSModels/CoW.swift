public protocol _Cloneable {
    func clone() -> Self
}

@dynamicMemberLookup
@usableFromInline
package struct CoW<Boxed>: @unchecked Sendable where Boxed: _Cloneable & AnyObject {
    @usableFromInline
    package var _value: Boxed

    @inlinable
    init(_ value: Boxed) {
        self._value = value
    }

    @inlinable
    package subscript<T>(dynamicMember member: KeyPath<Boxed, T>) -> T {
        _read {
            yield self._value[keyPath: member]
        }
    }

    @inlinable
    mutating func withMutation(_ mutation: (Boxed) throws -> Void) rethrows {
        if isKnownUniquelyReferenced(&self._value) {
            try mutation(self._value)
        } else {
            self._value = self._value.clone()
            try mutation(self._value)
        }
    }
}

extension CoW: Equatable where Boxed: Equatable {}
extension CoW: Hashable where Boxed: Hashable {}
