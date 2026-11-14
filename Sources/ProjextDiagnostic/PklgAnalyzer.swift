import Foundation

struct PklgRecord {
    let seconds: UInt32
    let micros: UInt32
    let kind: UInt8
    let payload: [UInt8]
    var timestamp: Double { Double(seconds) + Double(micros) / 1_000_000 }
}

enum PklgParseError: Error, CustomStringConvertible {
    case invalid(Int, String)
    var description: String {
        switch self { case .invalid(let offset, let reason): return "Offset \(offset): \(reason)" }
    }
}

enum PklgReader {
    private static func u32(_ b: [UInt8], _ i: Int) -> UInt32 {
        UInt32(b[i]) | UInt32(b[i + 1]) << 8 |
        UInt32(b[i + 2]) << 16 | UInt32(b[i + 3]) << 24
    }

    static func decode(_ bytes: [UInt8]) throws -> [PklgRecord] {
        var index = 0
        var output: [PklgRecord] = []
        while index < bytes.count {
            guard bytes.count - index >= 13 else {
                throw PklgParseError.invalid(index, "truncated header")
            }
            let size = Int(u32(bytes, index))
            guard size >= 9, size <= bytes.count - index - 4 else {
                throw PklgParseError.invalid(index, "invalid record size")
            }
            let micros = u32(bytes, index + 8)
            guard micros < 1_000_000 else {
                throw PklgParseError.invalid(index, "invalid microseconds")
            }
            let end = index + 4 + size
            output.append(PklgRecord(seconds: u32(bytes, index + 4),
                                     micros: micros,
                                     kind: bytes[index + 12],
                                     payload: Array(bytes[(index + 13)..<end])))
            index = end
        }
        return output
    }
}

struct CandidatePacket {
    let timestamp: Double
    let side: String
    let firstField: UInt8
    let secondField: UInt8

    static func detect(_ record: PklgRecord) -> CandidatePacket? {
        let p = record.payload
        guard record.kind == 3, p.count == 184,
              Array(p[18..<22]) == [0xA4, 0, 4, 0],
              p[23] == 2, p[25] == 9 else { return nil }
        let side: String
        switch p[26] {
        case 2: side = "LEFT"
        case 1: side = "RIGHT"
        default: return nil
        }
        return CandidatePacket(timestamp: record.timestamp, side: side,
                               firstField: p[22], secondField: p[24])
    }
}

enum PklgAnalyzer {
    static func analyze(path: String) throws {
        let bytes = Array(try Data(contentsOf: URL(fileURLWithPath: path)))
        let records = try PklgReader.decode(bytes)
        let start = records.first?.timestamp ?? 0
        let hits = records.compactMap(CandidatePacket.detect)
        print("File: \(URL(fileURLWithPath: path).lastPathComponent)")
        print("Records: \(records.count), candidate packets: \(hits.count)")
        for hit in hits {
            print(String(format: "t=+%.3fs candidate_side=%@ fieldA=0x%02X fieldB=0x%02X",
                         hit.timestamp - start, hit.side, hit.firstField, hit.secondField))
        }
        print("CAUTION: candidate_side is inferred from controlled captures, not a verified Apple protocol field.")
        print("No hold-start/release or live Bluetooth access is provided by this analyzer.")
    }
}
