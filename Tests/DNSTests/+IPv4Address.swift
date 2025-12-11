import Endpoint

#if canImport(Darwin)
import Darwin
#elseif os(Windows)
import ucrt
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Bionic)
import Bionic
#elseif canImport(WASILibc)
import WASILibc
#else
#error("The +IPv4Address module was unable to identify your C library.")
#endif

extension IPv4Address {
    static let defaultTestDNSServer: Self = {
        if let testDNSServerIPV4Address = Self.getEnvVar(
            name: "SWIFT_DNS_TEST_DNS_SERVER_IPV4_ADDRESS"
        ),
            !testDNSServerIPV4Address.isEmpty
        {
            print("*** Using test DNS server")
            return IPv4Address(testDNSServerIPV4Address)!
        }
        return IPv4Address(8, 8, 4, 4)
    }()

    private static func getEnvVar(name: String) -> String? {
        getenv(name).map {
            String(cString: $0)
        }
    }
}
