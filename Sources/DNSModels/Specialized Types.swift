/// A ``Message`` that provides convenient access to its ``answers`` by taking care of unwrapping them to ``SpecializedRecord``.
///
/// This type implements ``@dynamicMemberLookup`` over the ``message``, then shadows ``message.answers`` which
/// is of type ``[Record]``, by providing a ``answers`` property which is of the specialized type ``[SpecializedRecord<RDataType>]``.
@dynamicMemberLookup
public struct SpecializedMessage<RDataType: RDataConvertible>: Sendable {
    public var message: Message

    /// TODO: use a view type instead of accumulating into an array
    /// TODO: can do more than just `answers`?

    public var answers: [SpecializedRecord<RDataType>] {
        get {
            self.message.answers.map {
                SpecializedRecord(record: $0)
            }
        }
        set {
            self.message.answers = TinyFastSequence(
                newValue.map(\.record)
            )
        }
    }

    public subscript<T>(dynamicMember member: KeyPath<Message, T>) -> T {
        /// FIXME: use `read`/`modify` accessors
        get {
            self.message[keyPath: member]
        }
    }

    public subscript<T>(dynamicMember member: WritableKeyPath<Message, T>) -> T {
        /// FIXME: use `read`/`modify` accessors
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

/// A ``Record`` that provides convenient access to its ``rdata`` by taking care of unwrapping it to ``RDataType``.
///
/// This type implements ``@dynamicMemberLookup`` over the ``record``, then shadows ``record.rdata`` which
/// is of type ``RData``, by providing a ``rdata`` property which is of the specialized type ``RDataType``.
@dynamicMemberLookup
public struct SpecializedRecord<RDataType: RDataConvertible>: Sendable {
    public var record: Record
    public var rdata: RDataType {
        get throws {
            try RDataType(rdata: self.record.rdata)
        }
    }

    public mutating func setRData(_ specializedRData: RDataType) {
        self.record.rdata = specializedRData.toRData()
    }

    public subscript<T>(dynamicMember member: KeyPath<Record, T>) -> T {
        /// FIXME: use `read`/`modify` accessors
        get {
            self.record[keyPath: member]
        }
    }

    public subscript<T>(dynamicMember member: WritableKeyPath<Record, T>) -> T {
        /// FIXME: use `read`/`modify` accessors
        get {
            self.record[keyPath: member]
        }
        set {
            self.record[keyPath: member] = newValue
        }
    }

    public init(record: Record) {
        self.record = record
    }
}
