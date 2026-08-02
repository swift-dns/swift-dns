import DNSModels
import Testing

@Suite
struct MultipleQTypesTests {
    @Test func ednsCodesMatchTheIANARegistry() {
        #expect(EDNSCode.mqtypeQuery.rawValue == 20)
        #expect(EDNSCode.mqtypeResponse.rawValue == 21)
        #expect(EDNSCode(20) == .mqtypeQuery)
        #expect(EDNSCode(21) == .mqtypeResponse)
    }

    @Test func knownDataTypesAreDataTypes() {
        let dataTypes: [RecordType] = [
            .A, .AAAA, .CAA, .CDNSKEY, .CDS, .CERT, .CNAME, .CSYNC, .DNSKEY, .DS, .HINFO, .HTTPS,
            .KEY, .MX, .NAPTR, .NS, .NSEC, .NSEC3, .NSEC3PARAM, .NULL, .OPENPGPKEY, .PTR, .RRSIG,
            .SIG, .SOA, .SRV, .SSHFP, .SVCB, .TLSA, .TXT,
        ]
        for recordType in dataTypes {
            #expect(recordType.isDataType, "\(recordType.debugDescription)")
        }
    }

    @Test func knownMetaAndQTypesAreNotDataTypes() {
        let metaAndQTypes: [RecordType] = [
            .unknown(0),
            .OPT,
            .unknown(249),
            .TSIG,
            .IXFR,
            .AXFR,
            .unknown(253),
            .unknown(254),
            .ANY,
        ]
        for recordType in metaAndQTypes {
            #expect(!recordType.isDataType, "\(recordType.debugDescription)")
        }
    }

    @Test func dataTypeRangeBoundariesFollowRFC6895() {
        #expect(!RecordType(0).isDataType)
        #expect(RecordType(1).isDataType)
        #expect(RecordType(40).isDataType)
        #expect(!RecordType(41).isDataType)
        #expect(RecordType(42).isDataType)
        #expect(RecordType(127).isDataType)
        #expect(!RecordType(128).isDataType)
        #expect(!RecordType(255).isDataType)
        #expect(RecordType(256).isDataType)
        #expect(RecordType(32_768).isDataType)
        #expect(RecordType(32_769).isDataType)
        #expect(RecordType(61_439).isDataType)
        #expect(!RecordType(61_440).isDataType)
        #expect(!RecordType(65_279).isDataType)
        #expect(!RecordType(65_280).isDataType)
        #expect(!RecordType(65_534).isDataType)
        #expect(!RecordType(65_535).isDataType)
    }

    @available(SwiftStdlib 5.1, *)
    @Test func decodeMQTYPEQueryOption() throws {
        var buffer = DNSBuffer(bytes: [0, 28, 0, 65])

        let option = try EDNSOption(from: &buffer, code: .mqtypeQuery)

        guard case .mqtypeQuery(let multipleQTypes) = option else {
            Issue.record("Expected an mqtypeQuery option but got \(option)")
            return
        }
        #expect(multipleQTypes.recordTypes == [.AAAA, .HTTPS])
        #expect(buffer.readableBytes == 0)
    }

    @available(SwiftStdlib 5.1, *)
    @Test func decodeMQTYPEResponseOption() throws {
        var buffer = DNSBuffer(bytes: [0, 28, 0, 65])

        let option = try EDNSOption(from: &buffer, code: .mqtypeResponse)

        guard case .mqtypeResponse(let multipleQTypes) = option else {
            Issue.record("Expected an mqtypeResponse option but got \(option)")
            return
        }
        #expect(multipleQTypes.recordTypes == [.AAAA, .HTTPS])
        #expect(buffer.readableBytes == 0)
    }

    /// Section 3.4 of the RFC explicitly allows an MQTYPE-Response option to carry an empty list.
    @available(SwiftStdlib 5.1, *)
    @Test func decodeMQTYPEResponseOptionWithAnEmptyList() throws {
        var buffer = DNSBuffer()

        let option = try EDNSOption(from: &buffer, code: .mqtypeResponse)

        guard case .mqtypeResponse(let multipleQTypes) = option else {
            Issue.record("Expected an mqtypeResponse option but got \(option)")
            return
        }
        #expect(multipleQTypes.recordTypes == [])
    }

    /// Section 3.3 of the RFC requires a FORMERR for an MQTYPE-Query option with an empty list.
    @available(SwiftStdlib 5.1, *)
    @Test func decodeMQTYPEQueryOptionWithAnEmptyListThrows() throws {
        var buffer = DNSBuffer()

        do {
            let option = try EDNSOption(from: &buffer, code: .mqtypeQuery)
            Issue.record("Expected the decoding to throw but got \(option)")
        } catch let error as EDNSOption.MultipleQTypes.ValidationError {
            #expect(error.reason == .listMustNotBeEmpty)
            #expect(error.recordTypes == [])
        }
    }

    @available(SwiftStdlib 5.1, *)
    @Test func decodeMQTYPEOptionWithATrailingHalfRecordTypeThrows() throws {
        var buffer = DNSBuffer(bytes: [0, 28, 0])

        #expect(throws: ProtocolError.self) {
            try EDNSOption(from: &buffer, code: .mqtypeQuery)
        }
    }

    /// Section 3.3 of the RFC requires a FORMERR for a QTx corresponding to a non-data RRTYPE.
    @available(SwiftStdlib 5.1, *)
    @Test func decodeMQTYPEOptionWithANonDataRecordTypeThrows() throws {
        var buffer = DNSBuffer(bytes: [0, 28, 0, 255])

        do {
            let option = try EDNSOption(from: &buffer, code: .mqtypeQuery)
            Issue.record("Expected the decoding to throw but got \(option)")
        } catch let error as EDNSOption.MultipleQTypes.ValidationError {
            #expect(error.reason == .recordTypeMustBeADataType(.ANY))
            #expect(error.recordTypes == [.AAAA, .ANY])
        }
    }

    /// Section 3.3 and section 3.5 of the RFC both make a duplicated QTx invalid.
    @available(SwiftStdlib 5.1, *)
    @Test func decodeMQTYPEOptionWithADuplicateRecordTypeThrows() throws {
        var buffer = DNSBuffer(bytes: [0, 28, 0, 65, 0, 28])

        do {
            let option = try EDNSOption(from: &buffer, code: .mqtypeResponse)
            Issue.record("Expected the decoding to throw but got \(option)")
        } catch let error as EDNSOption.MultipleQTypes.ValidationError {
            #expect(error.reason == .recordTypeMustNotBeRepeated(.AAAA))
            #expect(error.recordTypes == [.AAAA, .HTTPS, .AAAA])
        }
    }

    /// The set-based duplicate detection only kicks in past `maxCountForLinearDuplicateScan`.
    @available(SwiftStdlib 5.1, *)
    @Test func aDuplicateRecordTypeIsDetectedInALongList() throws {
        let count = EDNSOption.MultipleQTypes.maxCountForLinearDuplicateScan + 1
        var recordTypes = TinyFastSequence<RecordType>(
            (0..<count).map { RecordType(UInt16(256 + $0)) }
        )
        recordTypes.append(RecordType(256))

        do {
            let multipleQTypes = try EDNSOption.MultipleQTypes(
                recordTypes: recordTypes,
                allowsEmptyList: false
            )
            Issue.record("Expected the validation to throw but got \(multipleQTypes)")
        } catch {
            #expect(error.reason == .recordTypeMustNotBeRepeated(RecordType(256)))
        }
    }

    @available(SwiftStdlib 5.1, *)
    @Test func aListThatDoesNotFitInTheOptionLengthIsRejected() throws {
        let count = Int(UInt16.max / 2) + 1
        let recordTypes = TinyFastSequence<RecordType>(
            (0..<count).map { RecordType(UInt16(256 + $0)) }
        )

        do {
            let multipleQTypes = try EDNSOption.MultipleQTypes(
                recordTypes: recordTypes,
                allowsEmptyList: false
            )
            Issue.record("Expected the validation to throw but got \(multipleQTypes)")
        } catch {
            #expect(error.reason == .listMustNotContainMoreThan32767RecordTypes(actualCount: count))
        }
    }

    @available(SwiftStdlib 5.1, *)
    @Test func setRecordTypesValidatesTheNewList() throws {
        var multipleQTypes = try EDNSOption.MultipleQTypes(
            recordTypes: [.AAAA, .HTTPS],
            allowsEmptyList: false
        )

        try multipleQTypes.setRecordTypes([.A], allowsEmptyList: false)
        #expect(multipleQTypes.recordTypes == [.A])

        do {
            try multipleQTypes.setRecordTypes([], allowsEmptyList: false)
            Issue.record("Expected the validation to throw")
        } catch {
            #expect(error.reason == .listMustNotBeEmpty)
        }
        #expect(multipleQTypes.recordTypes == [.A])

        try multipleQTypes.setRecordTypes([], allowsEmptyList: true)
        #expect(multipleQTypes.recordTypes == [])
    }

    /// Mirrors the query of Appendix A.1 of the RFC, where a stub asks for A and additionally
    /// requests AAAA and HTTPS, and the recursive server answers with both of them.
    @available(SwiftStdlib 5.1, *)
    @Test func encodeAndDecodeMQTYPEOptionsThroughOPT() throws {
        let opt = OPT(
            options: [
                (
                    .mqtypeQuery,
                    .mqtypeQuery(
                        try EDNSOption.MultipleQTypes(
                            recordTypes: [.AAAA, .HTTPS],
                            allowsEmptyList: false
                        )
                    )
                ),
                (
                    .mqtypeResponse,
                    .mqtypeResponse(
                        try EDNSOption.MultipleQTypes(
                            recordTypes: [.AAAA, .HTTPS],
                            allowsEmptyList: true
                        )
                    )
                ),
            ]
        )

        var buffer = DNSBuffer()
        try opt.encode(into: &buffer)

        #expect(
            buffer == DNSBuffer(bytes: [0, 20, 0, 4, 0, 28, 0, 65, 0, 21, 0, 4, 0, 28, 0, 65])
        )

        let decoded = try OPT(from: &buffer)

        #expect(decoded.options.count == 2)
        #expect(decoded.options.first?.0 == .mqtypeQuery)
        #expect(decoded.options.first?.1 == opt.options.first?.1)
        #expect(decoded.options.last?.0 == .mqtypeResponse)
        #expect(decoded.options.last?.1 == opt.options.last?.1)
    }

    /// Mirrors Appendix A.3 of the RFC, where the server could not merge the additional response
    /// and therefore returns an MQTYPE-Response option carrying an empty list.
    @available(SwiftStdlib 5.1, *)
    @Test func encodeAndDecodeAnEmptyMQTYPEResponseThroughOPT() throws {
        let opt = OPT(
            options: [
                (
                    .mqtypeResponse,
                    .mqtypeResponse(
                        try EDNSOption.MultipleQTypes(
                            recordTypes: [],
                            allowsEmptyList: true
                        )
                    )
                )
            ]
        )

        var buffer = DNSBuffer()
        try opt.encode(into: &buffer)

        #expect(buffer == DNSBuffer(bytes: [0, 21, 0, 0]))

        let decoded = try OPT(from: &buffer)

        #expect(decoded.options.count == 1)
        #expect(decoded.options.first?.0 == .mqtypeResponse)
        #expect(decoded.options.first?.1 == opt.options.first?.1)
    }
}
