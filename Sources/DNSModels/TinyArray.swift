@available(swiftDNSApplePlatforms 26, *)
struct TinyArray<let count: Int, Element>: ~Copyable {
    enum Base: ~Copyable {
        case inline(InlineArray<count, Element>, count: Int)
        case heap([Element])
    }

    var _base: Base
    let terminator: Element

    package init(terminator: Element) {
        self._base = .inline(InlineArray<count, Element>(repeating: terminator), count: 0)
        self.terminator = terminator
    }

    init(_base: consuming Base, terminator: Element) {
        self._base = _base
        self.terminator = terminator
    }

    mutating func append(_ element: Element) {
        switch consume self._base {
        case .inline(var inline, let currentCount):
            assert(currentCount <= count)
            if currentCount == count {
                var array = [Element]()
                array.reserveCapacity(count + 1)
                for i in 0..<currentCount {
                    array.append(inline[i])
                }
                array.append(element)
                self = .init(
                    _base: .heap(array),
                    terminator: self.terminator
                )
            } else {
                inline[currentCount] = element
                self = .init(
                    _base: .inline(inline, count: currentCount + 1),
                    terminator: self.terminator
                )
            }
        case .heap(var array):
            assert(array.count > count)
            array.append(element)
            self = .init(
                _base: .heap(array),
                terminator: self.terminator
            )
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension TinyArray /*: Sequence */ {
    package consuming func makeIterator() -> Iterator {
        Iterator(base: self)
    }

    package struct Iterator: ~Copyable /*, IteratorProtocol */ {
        var base: TinyArray<count, Element>
        var ended = false

        init(base: consuming TinyArray<count, Element>) {
            self.base = base
            self.ended = false
        }

        package mutating func next() -> Element? {
            if ended {
                return nil
            }

            switch consume self.base._base {
            case .inline(let inline, let currentCount):
                if currentCount == 0 {
                    ended = true
                    self = .init(base: base)
                    return nil
                }
                let element = inline[currentCount - 1]
                // inline[currentCount - 1] = self.base.terminator
                self = .init(
                    base: .init(
                        _base: .inline(inline, count: currentCount - 1),
                        terminator: self.base.terminator
                    )
                )
                return element
            case .heap(var array):
                if array.count == 0 {
                    ended = true
                    self = .init(base: base)
                    return nil
                }
                let element = array.removeLast()
                self = .init(base: .init(_base: .heap(array), terminator: self.base.terminator))
                return element
            }
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension TinyArray: Sendable where Element: Sendable {}

@available(swiftDNSApplePlatforms 26, *)
extension TinyArray.Base: Sendable where Element: Sendable {}
