#if swift(<6.2.3)
#error(
    """
    This package requires Swift 6.2.3,
    which is available on Xcode 26.2,
    and via swiftly (https://www.swift.org/install/):
    ```
    swiftly install 6.2.3
    swiftly use 6.2.3
    ```

    Or you can use a Docker image with Swift 6.2.3+ installed (https://hub.docker.com/_/swift/tags).

    The reason this error exists like this, is that there is a bug in Xcode 26.2 where Xcode
    think it has Swift 6.2.1 installed during Package resolution, while in fact it does correctly
    have Swift 6.2.3 installed.

    This error will be removed when a new Xcode is release with a bug fix. 
    """
)
#endif
