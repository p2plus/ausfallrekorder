import XCTest
@testable import RecorderCore

final class ReportTests: XCTestCase {
    func testLabelsCannotInjectHTMLAndEmptyRecordingHasNoUptimeClaim() {
        let html = Report.html(Recording(label: "<script>alert(1)</script>"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
        XCTAssertFalse(html.contains("<script>alert(1)</script>"))
        XCTAssertTrue(html.contains("Keine Messwerte"))
        XCTAssertFalse(html.contains("100 %"))
    }

    func testNonOverlappingRecordingsDoNotClaimSharedOutages() {
        var a = Recording(label: "WiFi", started: Date(timeIntervalSince1970: 1000))
        a.samples = [Sample(at: a.started, duration: 2, external: false, https: false)]
        var b = Recording(label: "LAN", started: Date(timeIntervalSince1970: 2000))
        b.samples = [Sample(at: b.started, duration: 2, external: false, https: false)]
        XCTAssertTrue(Report.html(a, comparing: b).contains("Keine gemeinsamen Messfenster"))
    }
}
