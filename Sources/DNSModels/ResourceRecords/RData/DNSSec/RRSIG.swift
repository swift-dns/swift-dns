/// RRSIG is really a derivation of the original SIG record data. See SIG for more documentation
public struct RRSIG: Sendable {
    public let value: SIG
}
