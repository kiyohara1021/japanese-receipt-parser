import Foundation

/// Extracts a merchant candidate and a plausible total from Japanese receipt
/// OCR text using deterministic, local-only rules.
///
/// Pass lines in top-to-bottom reading order. The result is a candidate for
/// human review, not a verified accounting record.
public struct ReceiptParser: Sendable {
    private static let totalKeywords = [
        "合計", "合 計", "総計", "お買上げ計", "お買上計", "お会計", "ご請求", "total",
    ]

    private static let ignoredKeywords = [
        "電話", "tel", "fax", "登録番号", "会員", "ポイント", "お預り", "お預かり",
        "おつり", "お釣り", "釣銭", "レジ", "取引", "no.", "№",
    ]

    /// Receipt titles that often sit above the merchant name. A line that is
    /// exactly one of these (ignoring spaces and brackets) is not a merchant.
    private static let receiptHeadings: Set<String> = [
        "領収書", "領収証", "レシート", "お客様控え", "お客様控", "お客さま控え", "控え",
        "再発行", "明細書", "ご利用明細", "ご利用明細書", "receipt",
    ]

    /// Greetings printed at the top or bottom of a receipt.
    private static let greetingFragments = [
        "ありがとうございま", "いらっしゃいませ", "ご来店", "またのお越し", "毎度",
    ]

    /// Larger values are much more likely to be barcodes or identifiers.
    private static let maximumPlausibleTotal = Decimal(9_999_999)

    public init() {}

    /// Parses OCR lines without network access or probabilistic inference.
    public func parse(lines: [String]) -> Receipt {
        let normalizedLines = lines
            .flatMap { $0.components(separatedBy: .newlines) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let keywordTotals = normalizedLines
            .filter { Self.isTotalLine($0) && !Self.isIgnoredLine($0) }
            .compactMap(Self.amount(in:))

        return Receipt(
            merchantName: normalizedLines.first(where: Self.isMerchantCandidate),
            totalAmount: keywordTotals.max() ?? Self.fallbackTotal(in: normalizedLines),
            lines: normalizedLines
        )
    }

    private static func isTotalLine(_ line: String) -> Bool {
        totalKeywords.contains { line.localizedCaseInsensitiveContains($0) }
    }

    private static func isIgnoredLine(_ line: String) -> Bool {
        ignoredKeywords.contains { line.localizedCaseInsensitiveContains($0) }
    }

    private static func isMerchantCandidate(_ line: String) -> Bool {
        guard !isIgnoredLine(line), !isTotalLine(line), !isHeadingOrGreeting(line) else { return false }

        return removingNonAmountNumbers(from: normalize(line))
            .replacing(/[0-9¥,\.\s]/, with: "")
            .contains { $0.isLetter }
    }

    private static func isHeadingOrGreeting(_ line: String) -> Bool {
        // NFKC rather than `normalize(_:)`: that transform also turns katakana into
        // half-width forms, while NFKC folds both half-width kana and full-width ASCII.
        let bare = line.precomposedStringWithCompatibilityMapping
            .replacing(/[\s\[\]()（）【】「」『』<>〈〉《》*＊・:：-]/, with: "")
            .lowercased()
        return receiptHeadings.contains(bare) || greetingFragments.contains { bare.contains($0) }
    }

    /// Without a total keyword, prefer the bottom-most yen-marked amount.
    /// Otherwise, use the largest plausible bare number.
    private static func fallbackTotal(in lines: [String]) -> Decimal? {
        let candidates = lines.filter { !isIgnoredLine($0) }

        if let yenAmount = candidates.reversed().lazy.compactMap(Self.yenAmount(in:)).first {
            return yenAmount
        }

        return candidates.compactMap(Self.amount(in:)).max()
    }

    private static func amount(in line: String) -> Decimal? {
        removingNonAmountNumbers(from: normalize(line))
            .matches(of: /[0-9][0-9,.]*/)
            .compactMap { decimalValue(of: String($0.output)) }
            .filter { $0 <= maximumPlausibleTotal }
            .max()
    }

    private static func yenAmount(in line: String) -> Decimal? {
        removingNonAmountNumbers(from: normalize(line))
            .matches(of: /[¥￥]\s?([0-9][0-9,.]*)/)
            .compactMap { decimalValue(of: String($0.output.1)) }
            .filter { $0 <= maximumPlausibleTotal }
            .max()
    }

    private static func normalize(_ line: String) -> String {
        line.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? line
    }

    /// Removes patterns that should not be interpreted as prices.
    private static func removingNonAmountNumbers(from line: String) -> String {
        line
            .replacing(/[0-9]{4}[年\/\-.] ?[0-9]{1,2}[月\/\-.] ?[0-9]{1,2}日?/, with: " ")
            .replacing(/[0-9]{1,2}:[0-9]{2}(:[0-9]{2})?/, with: " ")
            .replacing(/[0-9]{2,5}-[0-9]{1,4}-[0-9]{3,4}/, with: " ")
            .replacing(/T[0-9]{13}/, with: " ")
    }

    /// Japanese yen has no decimal fraction. OCR sometimes confuses a comma
    /// with a period, so a three-digit group is treated as a thousands group.
    private static func decimalValue(of token: String) -> Decimal? {
        let groups = token.components(separatedBy: CharacterSet(charactersIn: ",."))
        guard let first = groups.first, !first.isEmpty else { return nil }

        if groups.dropFirst().allSatisfy({ $0.count == 3 }) {
            return Decimal(string: groups.joined())
        }

        return Decimal(string: first)
    }
}
