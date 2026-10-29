import XCTest
@testable import RecorderCore

final class ReportTests: XCTestCase {
    func testReportsUseTheRequestedLanguageWithoutChangingUserLabels() {
        let recording = Recording(label: "Home WiFi")
        let english = Report.html(recording, language: .english)
        XCTAssertTrue(english.contains("lang=\"en\""))
        XCTAssertTrue(english.contains("No measurements"))
        XCTAssertFalse(english.contains("Keine Messwerte"))
        let chinese = Report.html(recording, language: .simplifiedChinese)
        XCTAssertTrue(chinese.contains("lang=\"zh-Hans\""))
        XCTAssertTrue(chinese.contains("暂无测量数据"))
        XCTAssertTrue(chinese.contains("Home WiFi"))
    }
    func testLabelsCannotInjectHTMLAndEmptyRecordingHasNoUptimeClaim() {
        let html = Report.html(Recording(label: "<script>alert(1)</script>"), language: .german)
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
        XCTAssertTrue(Report.html(a, comparing: b, language: .german).contains("Keine gemeinsamen Messfenster"))
    }
}
