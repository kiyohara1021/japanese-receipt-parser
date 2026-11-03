import Foundation
import XCTest
@testable import JapaneseReceiptParser

final class ReceiptParserTests: XCTestCase {
    private let parser = ReceiptParser()

    func testParsesAnonymousJapaneseFixture() throws {
        let fixtureURL = try XCTUnwrap(
            Bundle.module.url(
                forResource: "receipt_ja",
                withExtension: "txt",
                subdirectory: "Fixtures"
            )
        )
        let fixture = try String(contentsOf: fixtureURL, encoding: .utf8)
        let receipt = parser.parse(lines: fixture.components(separatedBy: .newlines))

        XCTAssertEqual(receipt.merchantName, "青空マーケット 架空中央店")
        XCTAssertEqual(receipt.totalAmount, 396)
        XCTAssertEqual(receipt.lines.count, 6)
    }

    func testFallsBackToLargestBareNumber() {
        let receipt = parser.parse(lines: ["架空カフェ", "コーヒー 500", "ケーキ 480"])
        XCTAssertEqual(receipt.totalAmount, 500)
    }

    func testPrefersBottomMostYenAmountWithoutKeyword() {
        let receipt = parser.parse(lines: ["架空カフェ", "コーヒー ¥480", "ケーキ ¥520", "¥1,000"])
        XCTAssertEqual(receipt.totalAmount, 1_000)
    }

    func testParsesFullWidthDigitsAndSymbols() {
        let receipt = parser.parse(lines: ["架空電器", "合計 ￥１２，８００"])
        XCTAssertEqual(receipt.totalAmount, 12_800)
    }

    func testTreatsMisreadPeriodAsThousandsSeparator() {
        let receipt = parser.parse(lines: ["架空電器", "合計 ¥12.800"])
        XCTAssertEqual(receipt.totalAmount, 12_800)
    }

    func testIgnoresDatePhoneInvoiceBarcodeAndTender() {
        let receipt = parser.parse(lines: [
            "2026/08/14 10:31",
            "TEL 03-1234-5678",
            "架空カフェ",
            "登録番号 T1234567890123",
            "4901234567894",
            "コーヒー 500",
            "お預り 10,000",
        ])

        XCTAssertEqual(receipt.merchantName, "架空カフェ")
        XCTAssertEqual(receipt.totalAmount, 500)
    }

    func testTotalKeywordWinsOverTender() {
        let receipt = parser.parse(lines: ["架空居酒屋", "お会計 3,850", "お預り 5,000"])
        XCTAssertEqual(receipt.totalAmount, 3_850)
    }

    func testIgnoredKeywordCannotBecomeKeywordTotal() {
        let receipt = parser.parse(lines: [
            "架空スーパー",
            "ポイント合計 9,999",
            "合計 1,280",
        ])
        XCTAssertEqual(receipt.totalAmount, 1_280)
    }

    func testSplitsMultilineInputAndDropsWhitespace() {
        let receipt = parser.parse(lines: [" 架空ストア\n2026/08/14 ", "  合計 ¥396  "])
        XCTAssertEqual(receipt.lines, ["架空ストア", "2026/08/14", "合計 ¥396"])
        XCTAssertEqual(receipt.rawText, "架空ストア\n2026/08/14\n合計 ¥396")
    }

    func testEmptyInputProducesEmptyCandidate() {
        let receipt = parser.parse(lines: ["", "   "])
        XCTAssertNil(receipt.merchantName)
        XCTAssertNil(receipt.totalAmount)
        XCTAssertTrue(receipt.lines.isEmpty)
    }

    func testReceiptCanBeEncodedAsJSON() throws {
        let receipt = parser.parse(lines: ["架空商店", "合計 ¥1,234"])
        let data = try JSONEncoder().encode(receipt)
        XCTAssertFalse(data.isEmpty)
    }

    func testIgnoresEraDatesWhenChoosingMerchant() {
        for header in ["令和7年10月1日", "R7.10.1", "令和元年5月1日", "平成31年4月30日"] {
            let receipt = parser.parse(lines: [header, "架空書店", "合計 ¥980"])
            XCTAssertEqual(receipt.merchantName, "架空書店", header)
        }
    }

    func testIgnoresTwoDigitYearAndWeekdayDates() {
        for header in ["25/10/01 12:30", "25-10-01", "10/01(水)", "10月1日（水）"] {
            let receipt = parser.parse(lines: [header, "架空カフェ", "コーヒー 45"])
            XCTAssertEqual(receipt.merchantName, "架空カフェ", header)
            XCTAssertEqual(receipt.totalAmount, 45, header)
        }
    }

    func testKeepsAmountsAndQuantitiesNextToDates() {
        let receipt = parser.parse(lines: ["架空商店", "25/10/01", "2点 合計 ¥1,000"])
        XCTAssertEqual(receipt.totalAmount, 1_000)
        XCTAssertEqual(parser.parse(lines: ["架空電器", "合計 ¥12.800"]).totalAmount, 12_800)
        XCTAssertEqual(parser.parse(lines: ["Hours 10.30", "Fictional Deli", "TOTAL ¥1,200"]).merchantName, "Hours 10.30")
    }
}

final class ImageTextRecognizerTests: XCTestCase {
    func testRejectsNonImageData() async {
        do {
            _ = try await ImageTextRecognizer().recognizeLines(from: Data("not an image".utf8))
            XCTFail("Expected invalidImage")
        } catch let error as ImageTextRecognizer.RecognitionError {
            XCTAssertEqual(error, .invalidImage)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
