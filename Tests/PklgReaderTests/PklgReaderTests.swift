import XCTest
@testable import ProjextDiagnostic

final class PklgReaderTests: XCTestCase {
    private func frame(_ payload: [UInt8]) -> [UInt8] {
        func little(_ n: UInt32) -> [UInt8] {
            [UInt8(truncatingIfNeeded: n), UInt8(truncatingIfNeeded: n >> 8),
             UInt8(truncatingIfNeeded: n >> 16), UInt8(truncatingIfNeeded: n >> 24)]
        }
        return little(UInt32(9 + payload.count)) + little(100) + little(500_000) + [3] + payload
    }

    func testTimestamp() throws {
        let record = try XCTUnwrap(PklgReader.decode(frame([0x11])).first)
        XCTAssertEqual(record.timestamp, 100.5, accuracy: 0.00001)
        XCTAssertEqual(record.payload, [0x11])
    }

    func testTruncatedRecord() {
        XCTAssertThrowsError(try PklgReader.decode([0, 1, 2]))
        XCTAssertThrowsError(try PklgReader.decode(Array(frame([1, 2]).dropLast())))
    }

    func testCandidateSideAndFalsePositive() throws {
        var p = [UInt8](repeating: 0, count: 184)
        p.replaceSubrange(18..<22, with: [0xA4, 0, 4, 0])
        p[22] = 0x82
        p[23] = 2; p[24] = 1; p[25] = 9; p[26] = 2
        let l = try XCTUnwrap(PklgReader.decode(frame(p)).first)
        XCTAssertEqual(CandidatePacket.detect(l)?.side, "LEFT")
        p[26] = 1
        let r = try XCTUnwrap(PklgReader.decode(frame(p)).first)
        XCTAssertEqual(CandidatePacket.detect(r)?.side, "RIGHT")
        p[25] = 0
        let bad = try XCTUnwrap(PklgReader.decode(frame(p)).first)
        XCTAssertNil(CandidatePacket.detect(bad))
    }
}
