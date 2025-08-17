public import protocol NIOCore.EventLoopGroup
import class NIOPosix.MultiThreadedEventLoopGroup

#if canImport(Network)
import class NIOTransportServices.NIOTSEventLoopGroup
#endif

@available(swiftDNSApplePlatforms 15, *)
extension DNSClient {
    /// Returns the default `EventLoopGroup` singleton for TCP connections, automatically selecting the best for the platform.
    ///
    /// This will select the concrete `EventLoopGroup` depending which platform this is running on.
    public static var defaultTCPEventLoopGroup: any EventLoopGroup {
        #if canImport(Network)
        if #available(OSX 10.14, iOS 12.0, tvOS 12.0, watchOS 6.0, *) {
            return NIOTSEventLoopGroup.singleton
        } else {
            return MultiThreadedEventLoopGroup.singleton
        }
        #else
        return MultiThreadedEventLoopGroup.singleton
        #endif
    }

    /// Returns the default `EventLoopGroup` singleton for UDP connections, automatically selecting the best for the platform.
    ///
    /// This is supposed to select the concrete `EventLoopGroup` depending which platform this is running on.
    /// Currently, it just returns the `MultiThreadedEventLoopGroup` singleton considering we don't
    /// have a darwin-specific event loop group for UDP.
    public static var defaultUDPEventLoopGroup: any EventLoopGroup {
        MultiThreadedEventLoopGroup.singleton
    }
}
