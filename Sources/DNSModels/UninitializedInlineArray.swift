struct UninitializedInlineArray<let count: Int, Element> {
    var storage: InlineArray<count, Element?>
    var count: Int

    var hasMoreCapacity: Bool {
        self.count < self.storage.count
    }

    var first: Element? {
        self.storage[0]
    }

    init() {
        precondition(count > 0, "count must be greater than 0")
        self.storage = InlineArray<count, Element?>(repeating: nil)
        self.count = 0
    }

    init(_ elements: [Element]) {
        precondition(elements.count <= count, "elements.count must be less than or equal to count")
        self.init()
        for (i, element) in elements.enumerated() {
            self.storage[i] = element
        }
        self.count = elements.count
    }

    mutating func append(_ element: Element) {
        precondition(self.count < self.storage.count, "count must be less than storage.count")
        self.storage[self.count] = element
        self.count += 1
    }
}

extension UninitializedInlineArray: Sequence {
    func makeIterator() -> Iterator {
        Iterator(base: self)
    }

    struct Iterator: IteratorProtocol {
        let base: UninitializedInlineArray<count, Element>
        var index: Int = 0

        mutating func next() -> Element? {
            defer { self.index += 1 }
            return self.base.storage[self.index]
        }
    }
}

extension UninitializedInlineArray: Sendable where Element: Sendable {}

extension UninitializedInlineArray: Equatable where Element: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }

        for i in 0..<lhs.count {
            guard lhs.storage[i] == rhs.storage[i] else {
                return false
            }
        }

        return true
    }
}

extension UninitializedInlineArray: Hashable where Element: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.count)
        for i in 0..<self.count {
            hasher.combine(self.storage[i])
        }
    }
}
