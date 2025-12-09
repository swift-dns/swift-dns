public import NIOCore

@available(swiftDNSApplePlatforms 10.15, *)
extension EventLoop {
    @usableFromInline
    var executor_Compatibility: any SerialExecutor {
        if #available(swiftDNSApplePlatforms 14, *) {
            return self.executor
        } else {
            return NIODefaultSerialEventLoopExecutor_Compatibility(self)
        }
    }
}

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
