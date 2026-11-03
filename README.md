# Japanese Receipt Parser

[![CI](https://github.com/kiyohara1021/japanese-receipt-parser/actions/workflows/ci.yml/badge.svg)](https://github.com/kiyohara1021/japanese-receipt-parser/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138.svg?logo=swift)](https://www.swift.org)

[日本語](README.ja.md)

An API-key-free Swift package that extracts a merchant candidate and a plausible total from Japanese receipt images. OCR runs entirely on device with Apple's Vision framework; parsing uses deterministic rules and has no third-party dependencies.

> [!IMPORTANT]
> OCR and parsing can be wrong. Always show extracted values to a person for confirmation before saving, accounting, reimbursement, payment, or any other consequential use.

## Why

Japanese receipts commonly contain full-width digits, yen symbols, invoice registration numbers, phone numbers, dates, tender, and OCR punctuation mistakes. This package handles those common sources of false totals without uploading receipt images. When no total keyword is found, the bottom-most amount marked as yen wins — `¥1,234`, `1,234円`, or `\1,234`, since OCR often reads `¥` as a backslash.

## Features

- On-device Japanese and English OCR with Apple Vision
- EXIF orientation handling and visual reading-order sorting
- Merchant and total candidates from Japanese receipt text
- Full-width number normalization
- Filters for dates, phone numbers, invoice IDs, barcodes, and tender
- Library and command-line interface
- No API key, network request, telemetry, or third-party package

## Requirements

- Swift 6.0+
- iOS 16+ or macOS 13+
- Apple platforms only because OCR uses Vision and ImageIO

## Installation

In Xcode, add this repository as a Swift Package dependency. In `Package.swift`:

```swift
.package(url: "https://github.com/kiyohara1021/japanese-receipt-parser.git", from: "0.1.0")
```

Then add `JapaneseReceiptParser` to your target dependencies.

## Usage

```swift
import JapaneseReceiptParser

let imageData = try Data(contentsOf: receiptImageURL)
let lines = try await ImageTextRecognizer().recognizeLines(from: imageData)
let candidate = ReceiptParser().parse(lines: lines)

// Required: let the user verify both fields before saving.
print(candidate.merchantName ?? "Needs review")
print(candidate.totalAmount ?? "Needs review")
```

You can also parse OCR text from stdin, a UTF-8 file, or an image:

```bash
printf '架空商店\n合計 ¥1,234\n' | swift run receipt-parser
swift run receipt-parser ./ocr-lines.txt
swift run receipt-parser --image ./receipt.jpg
```

The CLI prints JSON to stdout and a review reminder to stderr.

## Privacy and data flow

The package makes no network requests. `ImageTextRecognizer` passes image bytes directly to Apple's on-device Vision API. `ReceiptParser` is a pure local text parser. Your application is responsible for storage, logging, analytics, backups, and any later transmission of the result.

## Accuracy and scope

Version 0.1 extracts only a merchant candidate and a plausible yen total. It does not verify purchases, perform accounting, extract line-item tax details, or provide financial advice. Rules are intentionally inspectable and conservative. Anonymous fixtures are under `Tests/`.

## Development

```bash
swift build
swift test
swift run receipt-parser Tests/JapaneseReceiptParserTests/Fixtures/receipt_ja.txt
```

See [CONTRIBUTING.md](CONTRIBUTING.md), [SUPPORT.md](SUPPORT.md), [SECURITY.md](SECURITY.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [CHANGELOG.md](CHANGELOG.md).

## License

MIT. See [LICENSE](LICENSE).
