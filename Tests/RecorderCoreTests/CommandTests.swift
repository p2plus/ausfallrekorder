import XCTest
@testable import RecorderCore

final class CommandTests: XCTestCase, @unchecked Sendable {
    func testCollectsOutputAndExitStatus() async {
        let result = await Command.run("/bin/echo", ["hello"])
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.output.trimmingCharacters(in: .whitespacesAndNewlines), "hello")
        let failure = await Command.run("/bin/false", [])
        XCTAssertFalse(failure.success)
    }

    func testHungProbeIsTerminated() async {
        let start = Date()
        let result = await Command.run("/bin/sleep", ["10"], timeout: 0.1)
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.reason.contains(tr("Zeitlimit")))
        XCTAssertLessThan(Date().timeIntervalSince(start), 2)
    }

    func testMissingExecutableIsReported() async {
        let result = await Command.run("/no-such-recorder-program", [])
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.reason.contains(tr("Programm fehlt: %@", "/no-such-recorder-program")))
    }

    func testCancellationStopsTheActualProbe() async {
        let task = Task { await Command.run("/bin/sleep", ["10"], timeout: 10) }
        try? await Task.sleep(for: .milliseconds(50))
        let start = Date()
        task.cancel()
        let result = await task.value
        XCTAssertEqual(result.reason, tr("Abgebrochen"))
        XCTAssertLessThan(Date().timeIntervalSince(start), 2)
    }
}
