@usableFromInline
@available(swiftDNSApplePlatforms 26, *)
package struct TinyArray<let count: Int, Element: BitwiseCopyable> {
    @usableFromInline
    enum Base {
        case inline(InlineArray<count, Element>, count: Int)
        case heap([Element])
        case modifying
    }

    @usableFromInline
    var _base: Base

    @inlinable
    var count: Int {
        switch self._base {
        case .inline(_, let currentCount):
            return currentCount
        case .heap(let array):
            return array.count
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }

    @inlinable
    var capacity: Int {
        switch self._base {
        case .inline:
            return count
        case .heap(let array):
            return array.capacity
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }

    @inlinable
    var isEmpty: Bool {
        switch self._base {
        case .inline(_, let currentCount):
            return currentCount == 0
        case .heap(let array):
            return array.isEmpty
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }

    @inlinable
    var first: Element? {
        switch self._base {
        case .inline(let inline, let currentCount):
            return currentCount > 0 ? inline[0] : nil
        case .heap(let array):
            return array.first
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }

    @inlinable
    package init(fillingEmptySpacesWith terminator: Element) {
        self._base = .inline(InlineArray<count, Element>(repeating: terminator), count: 0)
    }

    init(_base: consuming Base) {
        self._base = _base
    }

    package init(_ elements: some Collection<Element>, terminator: Element) {
        switch elements.count {
        case 0...count:
            let elementsCount = elements.count
            let inline = InlineArray<count, Element>.init { idx in
                if elementsCount > idx {
                    let index = elements.index(elements.startIndex, offsetBy: idx)
                    return elements[index]
                } else {
                    return terminator
                }
            }
            self._base = .inline(inline, count: elements.count)
        default:
            self._base = .heap(Array(elements))
        }
    }

    subscript(index: Int) -> Element {
        get {
            switch self._base {
            case .inline(let inline, let currentCount):
                precondition(index >= 0 && index < currentCount, "Index out of bounds")
                return inline[index]
            case .heap(let array):
                precondition(index >= 0 && index < array.count, "Index out of bounds")
                return array[index]
            case .modifying:
                preconditionFailure("Cannot be in modifying state")
            }
        }
    }

    mutating func append(_ element: Element) {
        switch self._base {
        case .inline(var inline, let currentCount):
            assert(currentCount <= count)
            if currentCount == count {
                var array = [Element]()
                array.reserveCapacity(currentCount + 1)
                for idx in 0..<currentCount {
                    array.append(inline[idx])
                }
                array.append(element)
                self._base = .heap(array)
            } else {
                inline[currentCount] = element
                self._base = .inline(inline, count: currentCount + 1)
            }
        case .heap(var array):
            avoidingCoW { base in
                array.append(element)
                base = .heap(array)
            }
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }

    mutating func append(contentsOf elements: some Collection<Element>) {
        switch self._base {
        case .inline(var inline, let currentCount):
            assert(currentCount <= count)
            let futureCount = currentCount + elements.count
            if futureCount > count {
                var array = [Element]()
                array.reserveCapacity(futureCount)
                for idx in 0..<currentCount {
                    array.append(inline[idx])
                }
                array.append(contentsOf: elements)
                self._base = .heap(array)
            } else {
                for (idx, element) in elements.enumerated() {
                    inline[currentCount + idx] = element
                }
                self._base = .inline(inline, count: futureCount)
            }
        case .heap(var array):
            avoidingCoW { base in
                array.append(contentsOf: elements)
                base = .heap(array)
            }
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }

    mutating func mutatingMap(_ transform: (Element) -> Element) {
        switch self._base {
        case .inline(var inline, let currentCount):
            for idx in 0..<currentCount {
                inline[idx] = transform(inline[idx])
            }
            self._base = .inline(inline, count: currentCount)
        case .heap(var array):
            avoidingCoW { base in
                for idx in array.indices {
                    array[idx] = transform(array[idx])
                }
                base = .heap(array)
            }
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }

    mutating func reserveCapacityUpfront(_ minimumCapacity: Int) {
        guard minimumCapacity > self.capacity else {
            return
        }

        switch self._base {
        case .inline(let inline, let currentCount):
            /// At this point we need more capacity that `count`, so we need to allocate an array.
            var array = [Element]()
            array.reserveCapacity(minimumCapacity)
            for idx in 0..<currentCount {
                array.append(inline[idx])
            }
            self._base = .heap(array)
        case .heap(var array):
            array.reserveCapacity(minimumCapacity)
            self._base = .heap(array)
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }

    /// Copied from PostgresNIO although it's not like it's doing something complicated.
    ///
    /// So, uh...this function needs some explaining.
    ///
    /// While the state machine logic above is great, there is a downside to having all of the state machine data in
    /// associated data on enumerations: any modification of that data will trigger copy on write for heap-allocated
    /// data. That means that for _every operation on the state machine_ we will CoW our underlying state, which is
    /// not good.
    ///
    /// The way we can avoid this is by using this helper function. It will temporarily set state to a value with no
    /// associated data, before attempting the body of the function. It will also verify that the state machine never
    /// remains in this bad state.
    ///
    /// A key note here is that all callers must ensure that they return to a good state before they exit.
    ///
    /// Sadly, because it's generic and has a closure, we need to force it to be inlined at all call sites, which is
    /// not ideal.
    @inline(__always)
    private mutating func avoidingCoW<ReturnType>(
        _ body: (inout Base) -> ReturnType
    ) -> ReturnType {
        self._base = .modifying
        defer {
            assert(!self.isModifying)
        }
        return body(&self._base)
    }

    private var isModifying: Bool {
        if case .modifying = self._base {
            return true
        } else {
            return false
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension TinyArray: Sequence {
    @usableFromInline
    package consuming func makeIterator() -> Iterator {
        Iterator(tinyArray: self)
    }

    @usableFromInline
    package struct Iterator: IteratorProtocol {
        var tinyArray: TinyArray<count, Element>
        var ended = false

        init(tinyArray: consuming TinyArray<count, Element>) {
            self.tinyArray = tinyArray
            self.ended = false
        }

        @usableFromInline
        package mutating func next() -> Element? {
            if ended {
                return nil
            }

            switch self.tinyArray._base {
            case .inline(let inline, let currentCount):
                if currentCount == 0 {
                    ended = true
                    self = .init(tinyArray: .init(_base: .inline(inline, count: 0)))
                    return nil
                }
                let element = inline[currentCount - 1]
                self.tinyArray._base = .inline(inline, count: currentCount - 1)
                return element
            case .heap(var array):
                if array.count == 0 {
                    ended = true
                    self.tinyArray._base = .heap(array)
                    return nil
                }
                return self.tinyArray.avoidingCoW { base in
                    let element = array.removeLast()
                    base = .heap(array)
                    return element
                }
            case .modifying:
                preconditionFailure("Cannot be in modifying state")
            }
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension TinyArray: Equatable where Element: Equatable {
    @usableFromInline
    package static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }

        switch lhs._base {
        case .inline:
            switch rhs._base {
            case .inline:
                /// TODO: use memcmp or something?
                break
            default: break
            }
        case .heap(let lhs):
            switch rhs._base {
            case .heap(let rhs):
                return lhs == rhs
            default:
                return false
            }
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }

        for (lhs, rhs) in zip(lhs, rhs) {
            if lhs != rhs {
                return false
            }
        }

        return true
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension TinyArray: Hashable where Element: Hashable {
    @usableFromInline
    package func hash(into hasher: inout Hasher) {
        switch self._base {
        case .inline(var inline, _):
            inline.span.withUnsafeBytes {
                hasher.combine(bytes: $0)
            }
            /// To suppress the warning about the unused variable.
            /// The reason this is a var in the first place is to avoid wrong errors about
            /// inline escaping its scope and all.
            doNothing(&inline)
        case .heap(let array):
            hasher.combine(array)
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }

    func doNothing(_: inout InlineArray<count, Element>) {}
}

@available(swiftDNSApplePlatforms 26, *)
extension TinyArray: ExpressibleByArrayLiteral where Element == UInt8 {
    @usableFromInline
    package init(arrayLiteral elements: Element...) {
        self.init(elements, terminator: 0)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension TinyArray: CustomStringConvertible {
    @usableFromInline
    package var description: String {
        switch self._base {
        case .inline:
            return "TinyArray(inline: \(Array(self)))"
        case .heap(let array):
            return "TinyArray(heap: \(array))"
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension TinyArray: Sendable where Element: Sendable {}

@available(swiftDNSApplePlatforms 26, *)
extension TinyArray.Base: Sendable where Element: Sendable {}

@available(swiftDNSApplePlatforms 26, *)
extension Array {
    package init<let count: Int>(_ tinyArray: TinyArray<count, Element>) {
        switch tinyArray._base {
        case .inline(let inline, let currentCount):
            var array = [Element]()
            array.reserveCapacity(currentCount)
            for idx in 0..<currentCount {
                array.append(inline[idx])
            }
            self = array
        case .heap(let array):
            self = array
        case .modifying:
            preconditionFailure("Cannot be in modifying state")
        }
    }

    func doNothing<let count: Int>(_: inout InlineArray<count, Element>) {}
}
