@dynamicMemberLookup
public struct SpecializedMessage<RDataType: RDataConvertible>: Sendable {
    @dynamicMemberLookup
    public struct SpecializedRecord: Sendable {
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
            /// TODO: use `read`/`modify` accessors
            get {
                self.record[keyPath: member]
            }
        }

        public subscript<T>(dynamicMember member: WritableKeyPath<Record, T>) -> T {
            /// TODO: use `read`/`modify` accessors
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

    public var message: Message

    /// TODO: use a view type instead of accumulating into an array
    /// TODO: can do more than just `answers`?

    public var answers: [SpecializedRecord] {
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
        /// TODO: use `read`/`modify` accessors
        get {
            self.message[keyPath: member]
        }
    }

    public subscript<T>(dynamicMember member: WritableKeyPath<Message, T>) -> T {
        /// TODO: use `read`/`modify` accessors
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
