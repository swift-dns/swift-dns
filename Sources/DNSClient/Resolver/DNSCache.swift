public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 13, *)
@usableFromInline
package final actor DNSCache<ClockType: Clock> where ClockType.Duration == Duration {
    @usableFromInline
    struct DictionaryWithExpiration: Sendable, ~Copyable {
        /// [DomainName._data: Message]
        @usableFromInline
        var entries: [ByteBuffer: Message] = [:]
        @usableFromInline
        /// [DomainName._data: (expiresAt: ClockType.Instant, originalTTL: UInt32)]
        var expirationTable: [ByteBuffer: (expiresAt: ClockType.Instant, originalTTL: UInt32)] = [:]

        @inlinable
        init() {}

        @inlinable
        mutating func retrieve(
            key: ByteBuffer,
            clock: ClockType
        ) -> (message: Message, ttlHasAdvancedBy: UInt32)? {
            guard let (expiresAt, originalTTL) = self.expirationTable[key] else {
                return nil
            }
            let remainingTTL = clock.now.duration(to: expiresAt)
            if remainingTTL > Duration.zero {
                guard let entry = self.entries[key] else {
                    return nil
                }
                let remainingTTLRoundedDownSeconds = remainingTTL.components.seconds
                let ttlHasAdvancedBy = originalTTL - UInt32(remainingTTLRoundedDownSeconds)
                return (entry, ttlHasAdvancedBy)
            } else {
                self.entries.removeValue(forKey: key)
                self.expirationTable.removeValue(forKey: key)
                return nil
            }
        }

        @inlinable
        mutating func save(
            key: ByteBuffer,
            value: Message,
            expiresAt: ClockType.Instant,
            currentTTL: UInt32
        ) {
            if let (existingExpiresAt, _) = self.expirationTable[key],
                existingExpiresAt > expiresAt
            {
                return
            }
            self.entries[key] = value
            self.expirationTable[key] = (expiresAt, currentTTL)
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

        var message = message
        /// Cached additionals can cause problems
        message.additionals.removeAll()

        let effectiveTTL = min(ttl, self.ttlUpperLimit)
        let expiresAt = clock.now.advanced(by: .seconds(effectiveTTL))
        if message.header.checkingDisabled {
            self.entriesCheckingDisabled.save(
                key: domainName._data,
                value: message,
                expiresAt: expiresAt,
                currentTTL: effectiveTTL
            )
        } else {
            self.entriesCheckingEnabled.save(
                key: domainName._data,
                value: message,
                expiresAt: expiresAt,
                currentTTL: effectiveTTL
            )
        }
    }

    /// Returns a cached message for the `domainName` and `checkingDisabled`, if available.
    /// Prefers to return a message where `checkingDisabled` was false.
    /// Won't return a message where `checkingDisabled` was true, if
    /// the `checkingDisabled` parameter is false.
    @inlinable
    package func retrieve(domainName: DomainName, checkingDisabled: Bool) -> Message? {
        guard
            var (message, _ttlHasAdvancedBy) = self._retrieve(
                domainName: domainName,
                checkingDisabled: checkingDisabled
            )
        else {
            return nil
        }
        /// To silence the compiler
        self.actLikeWeAreMutatingTheValue(&_ttlHasAdvancedBy)

        /// We must have cleared the additionals before caching the message
        assert(message.additionals.isEmpty)
        self.adjustTTLs(in: &message, ttlHasAdvancedBy: _ttlHasAdvancedBy)

        return message
    }

    @inlinable
    func actLikeWeAreMutatingTheValue(_: inout UInt32) {}

    @inlinable
    func _retrieve(
        domainName: DomainName,
        checkingDisabled: Bool
    ) -> (message: Message, ttlHasAdvancedBy: UInt32)? {
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

    @inlinable
    func adjustTTLs(in message: inout Message, ttlHasAdvancedBy: UInt32) {
        self.adjustTTLs(in: &message.answers, ttlHasAdvancedBy: ttlHasAdvancedBy)
        self.adjustTTLs(in: &message.nameServers, ttlHasAdvancedBy: ttlHasAdvancedBy)
        self.adjustTTLs(in: &message.additionals, ttlHasAdvancedBy: ttlHasAdvancedBy)
        self.adjustTTLs(in: &message.signature, ttlHasAdvancedBy: ttlHasAdvancedBy)
    }

    @inlinable
    func adjustTTLs(
        in records: inout TinyFastSequence<Record>,
        ttlHasAdvancedBy: UInt32
    ) {
        for idx in 0..<records.count {
            records[idx].ttl -= ttlHasAdvancedBy
        }
    }
}
