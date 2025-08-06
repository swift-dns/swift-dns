/// A `Sequence` that does not heap allocate, if it carries no elements
public struct TinyFastSequence<Element>: Sequence {
    @usableFromInline
    enum Base {
        case none(reserveCapacity: Int)
        case n([Element])
    }

    @usableFromInline
    private(set) var base: Base

    @inlinable
    public init() {
        self.base = .none(reserveCapacity: 0)
    }

    @inlinable
    public subscript(index: Int) -> Element {
        switch self.base {
        case .none:
            preconditionFailure("Index out of bounds: \(index)")
        case .n(let array):
            return array[index]
        }
    }

    @inlinable
    public init(_ collection: some Collection<Element>) {
        switch collection.count {
        case 0:
            self.base = .none(reserveCapacity: 0)
        default:
            if let collection = collection as? [Element] {
                self.base = .n(collection)
            } else {
                self.base = .n(Array(collection))
            }
        }
    }

    @inlinable
    public var count: Int {
        switch self.base {
        case .none:
            return 0
        case .n(let array):
            return array.count
        }
    }

    @inlinable
    public var first: Element? {
        switch self.base {
        case .none:
            return nil
        case .n(let array):
            return array.first
        }
    }

    @inlinable
    public var isEmpty: Bool {
        switch self.base {
        case .none:
            return true
        case .n:
            return false
        }
    }

    @inlinable
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        switch self.base {
        case .none(let reservedCapacity):
            self.base = .none(reserveCapacity: Swift.max(reservedCapacity, minimumCapacity))
        case .n(var array):
            self.base = .none(reserveCapacity: 0)  // prevent CoW
            array.reserveCapacity(minimumCapacity)
            self.base = .n(array)
        }
    }

    @inlinable
    public mutating func append(_ element: Element) {
        switch self.base {
        case .none(let reserveCapacity):
            var new = [Element]()
            new.reserveCapacity(Swift.max(2, reserveCapacity))
            new.append(element)
            self.base = .n(new)

        case .n(var existing):
            self.base = .none(reserveCapacity: 0)  // prevent CoW
            existing.append(element)
            self.base = .n(existing)
        }
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(self)
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline
        private(set) var index: Int = 0
        @usableFromInline
        private(set) var backing: TinyFastSequence<Element>

        @inlinable
        init(_ backing: TinyFastSequence<Element>) {
            self.backing = backing
        }

        @inlinable
        public mutating func next() -> Element? {
            switch self.backing.base {
            case .none:
                return nil

            case .n(let array):
                if self.index < array.endIndex {
                    defer { self.index += 1 }
                    return array[self.index]
                }
                return nil
            }
        }
    }
}

extension TinyFastSequence: Equatable where Element: Equatable {}
extension TinyFastSequence.Base: Equatable where Element: Equatable {}

extension TinyFastSequence: Hashable where Element: Hashable {}
extension TinyFastSequence.Base: Hashable where Element: Hashable {}

extension TinyFastSequence: Sendable where Element: Sendable {}
extension TinyFastSequence.Base: Sendable where Element: Sendable {}

extension TinyFastSequence: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral elements: Element...) {
        switch elements.count {
        case 0:
            self.base = .none(reserveCapacity: 0)
        default:
            self.base = .n(elements)
        }
    }
}
