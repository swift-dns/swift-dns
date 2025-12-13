public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 13, *)
@usableFromInline
package final actor DNSCache<ClockType: Clock> where ClockType.Duration == Duration {
    @usableFromInline
    struct DictionaryWithExpiration: Sendable, ~Copyable {
        @usableFromInline
        var entries: [ByteBuffer: Message] = [:]
        @usableFromInline
        var expirationTable: [ByteBuffer: ClockType.Instant] = [:]

        @inlinable
        init() {}

        @inlinable
        mutating func retrieve(key: ByteBuffer, clock: ClockType) -> Message? {
            guard let expiresAt = self.expirationTable[key] else {
                return nil
            }
            if expiresAt > clock.now {
                return self.entries[key]
            } else {
                self.entries.removeValue(forKey: key)
                self.expirationTable.removeValue(forKey: key)
                return nil
            }
        }

        @inlinable
        mutating func save(key: ByteBuffer, value: Message, expiresAt: ClockType.Instant) {
            if let existingExpiresAt = self.expirationTable[key],
                existingExpiresAt > expiresAt
            {
                return
            }
            self.entries[key] = value
            self.expirationTable[key] = expiresAt
        }
    }

    @usableFromInline
    var entriesCheckingDisabled = DictionaryWithExpiration()
    @usableFromInline
    var entriesCheckingEnabled = DictionaryWithExpiration()
    /// Clock used to track time, for example in expiration times.
    @usableFromInline
    let clock: ClockType
    /// Max allowed TTL (Time-To-Live) in seconds.
    @usableFromInline
    let ttlUpperLimit: UInt32

    /// A description
    /// - Parameters:
    ///   - ttlUpperLimit: Max allowed TTL in seconds.
    ///   - clock: Clock used to track time, for example in expiration times.
    ///
    @inlinable
    package init(
        ttlUpperLimit: UInt32 = 172800,
        clock: ClockType = .continuous
    ) {
        self.clock = clock
        self.ttlUpperLimit = ttlUpperLimit
    }

    /// A description
    /// - Parameters:
    ///   - domainName: The domain name to cache the message for.
    ///     Must match the domain name in the `message.queries`.
    ///   - message: The message to cache.
    ///   - ttl: Time-To-Live in seconds.
    @inlinable
    package func cache(domainName: DomainName, message: Message, ttl: UInt32) {
        assert(message.queries.contains(where: { $0.domainName._data == domainName._data }))

        let effectiveTTL = min(ttl, self.ttlUpperLimit)
        let expiresAt = clock.now.advanced(by: .seconds(effectiveTTL))
        if message.header.checkingDisabled {
            self.entriesCheckingDisabled.save(
                key: domainName._data,
                value: message,
                expiresAt: expiresAt
            )
        } else {
            self.entriesCheckingEnabled.save(
                key: domainName._data,
                value: message,
                expiresAt: expiresAt
            )
        }
    }

    /// Returns a cached message for the `domainName` and `checkingDisabled`, if available.
    /// Prefers to return a message where `checkingDisabled` was false.
    /// Won't return a message where `checkingDisabled` was true, if
    /// the `checkingDisabled` parameter is false.
    ///
    /// FIXME: Adjust TTLs? Remove additionals?
    @inlinable
    package func retrieve(domainName: DomainName, checkingDisabled: Bool) -> Message? {
        let withCheckingEnabled = self.entriesCheckingEnabled.retrieve(
            key: domainName._data,
            clock: clock
        )

        if checkingDisabled {
            return withCheckingEnabled
                ?? self.entriesCheckingDisabled.retrieve(
                    key: domainName._data,
                    clock: clock
                )
        } else {
            /// Checking-disabled is false, meaning there might have been a DNSSEC validation in process.
            /// In this case we only return the cache where `checkingDisabled` was false too.
            return withCheckingEnabled
        }
    }
}
