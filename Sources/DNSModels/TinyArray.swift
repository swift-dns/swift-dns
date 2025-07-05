public struct TinyArray<let count: Int, Element> {
    enum Base {
        case inline(UninitializedInlineArray<count, Element>)
        case heap([Element])
    }

    var base: Base

    public init() {
        self.base = .inline(UninitializedInlineArray<count, Element>())
    }

    public var count: Int {
        switch self.base {
        case .inline(let array):
            return array.count
        case .heap(let array):
            return array.count
        }
    }

    public var first: Element? {
        switch self.base {
        case .inline(let array):
            return array.first
        case .heap(let array):
            return array.first
        }
    }

    public mutating func append(_ element: Element) {
        switch self.base {
        case .inline(var array):
            if array.hasMoreCapacity {
                array.append(element)
                self.base = .inline(array)
            } else {
                /// FIXME: is this initializer good enough?
                var array = Array(array)
                array.append(element)
                self.base = .heap(array)
            }
        case .heap(var array):
            /// FIXME: avoid CoW, if it happens at all
            array.append(element)
            self.base = .heap(array)
        }
    }
}

extension TinyArray: Sequence {
    public func makeIterator() -> Iterator {
        Iterator(base: self)
    }

    public struct Iterator: IteratorProtocol {
        enum Base {
            case inline(UninitializedInlineArray<count, Element>.Iterator)
            case heap(Array<Element>.Iterator)
        }

        var base: Base

        init(base: TinyArray<count, Element>) {
            switch base.base {
            case .inline(let array):
                self.base = .inline(array.makeIterator())
            case .heap(let array):
                self.base = .heap(array.makeIterator())
            }
        }

        public mutating func next() -> Element? {
            switch self.base {
            case .inline(var array):
                return array.next()
            case .heap(var array):
                return array.next()
            }
        }
    }
}

extension TinyArray: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init()
        switch elements.count {
            case 0...count:
                self.base = .inline(UninitializedInlineArray<count, Element>(elements))
            default:
                self.base = .heap(Array(elements))
        }
        for element in elements {
            self.append(element)
        }
    }
}

extension TinyArray.Base: Sendable where Element: Sendable {}
extension TinyArray.Base: Equatable where Element: Equatable {}
extension TinyArray.Base: Hashable where Element: Hashable {}

extension TinyArray: Sendable where Element: Sendable {}
extension TinyArray: Equatable where Element: Equatable {}
extension TinyArray: Hashable where Element: Hashable {}
