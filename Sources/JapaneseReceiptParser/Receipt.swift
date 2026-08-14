import Foundation

/// A deliberately small, reviewable result produced from receipt OCR text.
///
/// The parser does not claim that either field is correct. Applications must
/// show extracted values to a person before saving, paying, or accounting.
public struct Receipt: Codable, Equatable, Sendable {
    /// The first plausible merchant line in reading order.
    public let merchantName: String?

    /// A plausible total in Japanese yen. This is never a verified amount.
    public let totalAmount: Decimal?

    /// Normalized, non-empty OCR lines in top-to-bottom reading order.
    public let lines: [String]

    /// The normalized lines joined with a newline.
    public var rawText: String { lines.joined(separator: "\n") }

    public init(merchantName: String?, totalAmount: Decimal?, lines: [String]) {
        self.merchantName = merchantName
        self.totalAmount = totalAmount
        self.lines = lines
    }
}
