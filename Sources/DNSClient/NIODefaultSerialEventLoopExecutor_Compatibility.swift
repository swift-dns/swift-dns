public import NIOCore

@available(swiftDNSApplePlatforms 10.15, *)
extension EventLoop {
    #if canImport(Darwin)
    @usableFromInline
    #else
    @inlinable
    #endif
    var executor_Compatibility: any SerialExecutor {
        #if canImport(Darwin)
        if #available(swiftDNSApplePlatforms 14, *) {
            return self.executor
        } else {
            return NIODefaultSerialEventLoopExecutor_Compatibility(self)
        }
        #else
        self.executor
        #endif
    }
}

#if canImport(Darwin)
@available(swiftDNSApplePlatforms 10.15, *)
final class NIODefaultSerialEventLoopExecutor_Compatibility: SerialExecutor {
    let eventLoop: any EventLoop

    @inlinable
    init(_ eventLoop: any EventLoop) {
        self.eventLoop = eventLoop
    }

    @inlinable
    public func enqueue(_ job: UnownedJob) {
        self.eventLoop.execute {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    @inlinable
    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    @inlinable
    public func isSameExclusiveExecutionContext(
        other: NIODefaultSerialEventLoopExecutor_Compatibility
    ) -> Bool {
        self.eventLoop === other.eventLoop
    }
}
#endif
