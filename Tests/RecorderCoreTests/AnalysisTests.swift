import XCTest
@testable import RecorderCore

final class AnalysisTests: XCTestCase {
    let epoch = Date(timeIntervalSince1970: 1_000)
    func recording(_ samples: [Sample]) -> Recording {
        var r = Recording(label: "Desk", started: epoch, interval: 5)
        r.samples = samples
        return r
    }

    func testHTTPSWorksEvenWhenICMPIsBlocked() {
        XCTAssertEqual(Sample(at: epoch, gateway: false, external: false).health, .online)
    }

    func testFailedGatewayDoesNotProveALocalFaultWhenExternalIPsWork() {
        XCTAssertEqual(Sample(at: epoch, gateway: false, dns: false, https: false).health, .nameOrHTTPS)
    }

    func testClassifiesObservationsWithoutBlamingAProvider() {
        XCTAssertEqual(Sample(at: epoch, external: false, https: false).health, .internet)
        XCTAssertEqual(Sample(at: epoch, gateway: false, external: false, dns: false, https: false).health, .local)
        XCTAssertEqual(Sample(at: epoch, gateway: nil, external: false, dns: false, https: false).health, .unknown)
    }

    func testSleepGapIsNotCountedAsDowntime() {
        let r = recording([
            Sample(at: epoch, duration: 1, external: false, https: false),
            Sample(at: epoch.addingTimeInterval(3600), duration: 1, external: false, https: false)
        ])
        XCTAssertEqual(Analysis.incidents(r).count, 2)
        XCTAssertEqual(Analysis.observedSeconds(r), 2)
    }

    func testAdjacentFailedRoundsMergeButNotAcrossNetworkChanges() {
        let r = recording([
            Sample(at: epoch, duration: 1, external: false, https: false),
            Sample(at: epoch.addingTimeInterval(5), duration: 1, external: false, https: false),
            Sample(at: epoch.addingTimeInterval(10), duration: 1, external: false, https: false, network: "other")
        ])
        let incidents = Analysis.incidents(r)
        XCTAssertEqual(incidents.count, 2)
        XCTAssertEqual(incidents.first?.end, epoch.addingTimeInterval(6))
        // Only actual probe windows contribute to measured duration.
        XCTAssertEqual(Analysis.observedSeconds(r), 3)
    }

    func testComparisonUsesOverlapNotSimilarClockLabels() {
        let a = recording([Sample(at: epoch, duration: 3, external: false, https: false)])
        let b = recording([Sample(at: epoch.addingTimeInterval(2), duration: 4, external: false, https: false)])
        XCTAssertEqual(Analysis.simultaneousSeconds(a, b), 1)
        let c = recording([Sample(at: epoch.addingTimeInterval(60), duration: 2, external: false, https: false)])
        XCTAssertEqual(Analysis.simultaneousSeconds(a, c), 0)
    }

    func testEmptyRecordingIsNot100PercentUptime() {
        XCTAssertEqual(Analysis.observedSeconds(recording([])), 0)
        XCTAssertTrue(Analysis.incidents(recording([])).isEmpty)
    }
}
