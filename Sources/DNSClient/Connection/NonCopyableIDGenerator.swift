import Synchronization

@available(swiftDNS 1.0, *)
@usableFromInline
struct NonCopyableIDGenerator: ~Copyable, Sendable {
    let atomic: Atomic<Int>

    public init() {
        self.atomic = .init(0)
    }

    @usableFromInline
    func next() -> Int {
        self.atomic.wrappingAdd(1, ordering: .relaxed).newValue
    }
}
