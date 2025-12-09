/// A ``Message`` that provides convenient access to its ``answers`` by taking care of unwrapping them to ``SpecializedRecords``.
///
/// This type implements ``@dynamicMemberLookup`` over the ``message``, then shadows ``message.answers`` which
/// is of type ``[Record]``, by providing a ``answers`` property which is of the specialized type ``SpecializedRecords<RDataType>``.
@available(swiftDNSApplePlatforms 10.15, *)
@dynamicMemberLookup
public struct SpecializedMessage<RDataType: RDataConvertible>: Sendable {
    public var message: Message

    /// TODO: can do more than just `answers`?

    /// Use `message.answers` if you want to access the raw records, or if you want to modify them.
    public var answers: SpecializedRecords<RDataType> {
        SpecializedRecords(records: self.message.answers)
    }

    public subscript<T>(dynamicMember member: KeyPath<Message, T>) -> T {
        /// FIXME: use `read`/`modify` accessors?
        get {
            self.message[keyPath: member]
        }
    }

    public subscript<T>(dynamicMember member: WritableKeyPath<Message, T>) -> T {
        /// FIXME: use `read`/`modify` accessors?
        get {
            self.message[keyPath: member]
        }
        set {
            self.message[keyPath: member] = newValue
        }
    }

    public init(message: Message) {
        self.message = message
    }
}

/// A lazy sequence of ``Record``s that correspond to the given ``RDataType``.
///
/// For example you might use the dns resolver to resolve A records for `www.example.com.`.
/// In this case, `www.example.com.` only has CNAME records and no A records.
/// The upstream dns resolvers usually respond with 1-2 few CNAME records followed by 2+ A records.
///
/// What this type does is it filters out the CNAME records and only returns the A records to
/// make the end user's life easier as they never requested CNAME records anyway.
@available(swiftDNSApplePlatforms 10.15, *)
public struct SpecializedRecords<RDataType: RDataConvertible>: Sendable {
    public let records: TinyFastSequence<Record>

    public init(records: TinyFastSequence<Record>) {
        self.records = records
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension SpecializedRecords: Sequence {
    /// Complexity: O(n)
    @inlinable
    public var undeterminedCount: Int {
        self.count
    }

    /// A ``Record`` that provides convenient access to its ``rdata`` by taking care of unwrapping it to ``RDataType``.
    ///
    /// This type implements ``@dynamicMemberLookup`` over the ``record``, then shadows ``record.rdata`` which
    /// is of type ``RData``, by providing a ``rdata`` property which is of the specialized type ``RDataType``.
    ///
    /// This type guarantees that `rdata` and `record.rdata` are the same.
    /// That's the reason why both properties are marked as `private(set)`:
    /// So we don't have to manage syncing `rdata` and `record.rdata` manually.
    @dynamicMemberLookup
    public struct Element: Sendable {
        private(set) public var record: Record
        public var rdata: RDataType {
            try! RDataType(rdata: record.rdata)
        }

        public subscript<T>(dynamicMember member: KeyPath<Record, T>) -> T {
            _read {
                yield self.record[keyPath: member]
            }
        }

        public init(record: Record) throws(FromRDataTypeMismatchError<RDataType>) {
            self.record = record
            /// Test once to ensure the RData is expected
            _ = try RDataType(rdata: record.rdata)
        }
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(base: self)
    }

    /// An iterator over a ``SpecializedRecords`` that filters out records that
    /// don't correspond to ``RDataType``.
    public struct Iterator: Sendable, IteratorProtocol {
        @usableFromInline
        var baseIterator: TinyFastSequence<Record>.Iterator

        @inlinable
        init(base: SpecializedRecords<RDataType>) {
            self.baseIterator = base.records.makeIterator()
        }

        @inlinable
        public mutating func next() -> Element? {
            while true {
                guard let record = self.baseIterator.next() else {
                    return nil
                }

                /// If the record is of the wrong type, we skip it and continue to the next record.
                /// For example we could be getting both `CNAME` and `A` record for a domain name that
                /// is `CNAME`ed to another domain name with `A` records.
                ///
                /// So here if the query is a A query, we simply ignore the `CNAME`s.
                if let element = try? Element(record: record) {
                    return element
                } else {
                    /// Got a bad record. Skip and continue to the next record.
                    continue
                }
            }
        }
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension SpecializedRecords: Collection {
    public typealias Index = Int

    /// Complexity: O(n)
    @inlinable
    public var count: Int {
        self.records.count(where: { $0.recordType == RDataType.recordType })
    }

    /// Complexity: O(1)
    public var startIndex: Index {
        0
    }

    /// Complexity: O(n)
    public var endIndex: Index {
        self.count
    }

    public func index(after i: Index) -> Index {
        i + 1
    }

    public func index(before i: Index) -> Index {
        i - 1
    }

    /// Complexity: O(n)
    public subscript(position: Index) -> Element {
        var index = 0
        for record in records {
            if let element = try? Element(record: record) {
                if index == position {
                    return element
                }
                index += 1
            }
        }
        fatalError("Index \(position) is out of bounds of 0..<\(index)")
    }
}
