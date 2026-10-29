import XCTest
@testable import RecorderCore

final class StoreTests: XCTestCase {
    func withFile(_ test: (URL) throws -> Void) throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try test(dir.appendingPathComponent("test.afr"))
    }

    func testInterruptedRecordingKeepsCommittedSamples() throws {
        try withFile { url in
            let start = Date(timeIntervalSince1970: 1000)
            try Store.create(Recording(label: "LAN", started: start), at: url)
            try Store.append(Sample(at: start, duration: 2), to: url)
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            try handle.write(contentsOf: Data("{\"sample\":".utf8))
            try handle.close()
            let recovered = try Store.load(url)
            XCTAssertEqual(recovered.samples.count, 1)
            XCTAssertNil(recovered.ended)
        }
    }

    func testFinishedRecordingRoundTripsAndCannotBeOverwritten() throws {
        try withFile { url in
            let start = Date(timeIntervalSince1970: 1000)
            let r = Recording(label: "<Desk>", started: start)
            try Store.create(r, at: url)
            try Store.append(Sample(at: start, duration: 1.25), to: url)
            try Store.finish(at: start.addingTimeInterval(5), url: url)
            let saved = try Store.load(url)
            XCTAssertEqual(saved.samples.first?.duration, 1.25)
            XCTAssertEqual(saved.ended, start.addingTimeInterval(5))
            XCTAssertThrowsError(try Store.create(r, at: url))
            XCTAssertEqual(try Store.load(url).samples.count, 1)
        }
    }

    func testRejectsNegativeDurationsAndOutOfOrderSamples() throws {
        try withFile { url in
            let start = Date(timeIntervalSince1970: 1000)
            try Store.create(Recording(label: "LAN", started: start), at: url)
            try Store.append(Sample(at: start, duration: -1), to: url)
            XCTAssertThrowsError(try Store.load(url))
        }
        try withFile { url in
            let start = Date(timeIntervalSince1970: 1000)
            try Store.create(Recording(label: "LAN", started: start), at: url)
            try Store.append(Sample(at: start.addingTimeInterval(-5)), to: url)
            XCTAssertThrowsError(try Store.load(url))
        }
    }
}
