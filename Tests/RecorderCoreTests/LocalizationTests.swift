import XCTest
@testable import RecorderCore

final class LocalizationTests: XCTestCase {
    func testResolvesSystemLanguageAndFallsBackToEnglish() {
        XCTAssertEqual(Language.resolve("zh_CN"), .simplifiedChinese)
        XCTAssertEqual(Language.resolve("zh-Hans-SG"), .simplifiedChinese)
        XCTAssertEqual(Language.resolve("de-DE"), .german)
        XCTAssertEqual(Language.resolve("fr-FR"), .english)
    }

    func testFormatsUserVisibleCountsInBothNewLanguages() {
        XCTAssertEqual(L.text("%d Prüfungen", language: .english, arguments: [12]), "12 checks")
        XCTAssertEqual(L.text("%d Prüfungen", language: .simplifiedChinese, arguments: [12]), "12 次检查")
        XCTAssertEqual(L.text("Bericht: %@", language: .simplifiedChinese, arguments: ["a.html"]), "报告：a.html")
    }

    func testEveryTranslationKeepsItsFormatArguments() {
        let pattern = try! NSRegularExpression(pattern: "%[d@]")
        func tokens(_ text: String) -> [String] {
            pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { (text as NSString).substring(with: $0.range) }
        }
        for (source, translations) in L.entries {
            XCTAssertEqual(translations.count, 2, source)
            for translation in translations {
                XCTAssertFalse(translation.isEmpty, source)
                XCTAssertEqual(tokens(source), tokens(translation), source)
            }
        }
    }
}
