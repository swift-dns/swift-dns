/// A utility function that runs the body code only in debug builds, without
/// emitting compiler warnings.
///
/// This is currently the only way to do this in Swift: see
/// https://forums.swift.org/t/support-debug-only-code/11037 for a discussion.
/// Copied from https://github.com/apple/swift-nio/Sources/NIOPosix/Utilities.swift
@inlinable
package func debugOnly(_ body: () -> Void) {
    assert(
        {
            body()
            return true
        }()
    )
}
