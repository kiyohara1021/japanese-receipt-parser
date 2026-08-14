# Japanese Receipt Parser

[![CI](https://github.com/kiyohara1021/japanese-receipt-parser/actions/workflows/ci.yml/badge.svg)](https://github.com/kiyohara1021/japanese-receipt-parser/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138.svg?logo=swift)](https://www.swift.org)

[English](README.md)

日本語レシート画像から店舗名候補と合計金額候補を抽出する、APIキー不要のSwift Packageです。OCRはApple Visionにより完全に端末内で実行し、その後は決定的なルールで解析します。外部ライブラリには依存しません。

> [!IMPORTANT]
> OCRと解析結果は誤る可能性があります。保存・会計・経費精算・支払いなどに使う前に、必ず人が店舗名と金額を確認できる画面を設けてください。

## 特長

- Apple Visionによる日本語・英語のオンデバイスOCR
- EXIF回転情報と画面上の読み取り順に対応
- 店舗名候補と合計金額候補の抽出
- 全角数字・全角記号の正規化
- 日付、電話番号、適格請求書登録番号、バーコード、預り金を除外
- SwiftライブラリとCLIを提供
- APIキー、通信、テレメトリ、外部Packageがすべて不要

## 動作条件

- Swift 6.0以上
- iOS 16以上またはmacOS 13以上
- OCRがVisionとImageIOを使うためAppleプラットフォーム限定

## 導入

XcodeのSwift Package依存として、このリポジトリを追加します。`Package.swift`から使う場合は次のとおりです。

```swift
.package(url: "https://github.com/kiyohara1021/japanese-receipt-parser.git", from: "0.1.0")
```

利用するターゲットへ`JapaneseReceiptParser`を追加してください。

## 使い方

```swift
import JapaneseReceiptParser

let imageData = try Data(contentsOf: receiptImageURL)
let lines = try await ImageTextRecognizer().recognizeLines(from: imageData)
let candidate = ReceiptParser().parse(lines: lines)

// 必須: 保存前に利用者が両方を確認できるようにします。
print(candidate.merchantName ?? "要確認")
print(candidate.totalAmount ?? "要確認")
```

標準入力、UTF-8テキストファイル、画像をCLIから解析することもできます。

```bash
printf '架空商店\n合計 ¥1,234\n' | swift run receipt-parser
swift run receipt-parser ./ocr-lines.txt
swift run receipt-parser --image ./receipt.jpg
```

CLIは標準出力へJSON、標準エラー出力へ人による確認を促すメッセージを出します。

## プライバシーとデータの流れ

このPackageはネットワーク通信を行いません。`ImageTextRecognizer`は画像をAppleのオンデバイスVision APIへ直接渡します。`ReceiptParser`はローカルで完結するテキスト解析です。アプリ側の保存、ログ、分析、バックアップ、その後の外部送信については利用アプリの責任範囲です。

## 精度と対象範囲

バージョン0.1が抽出するのは店舗名候補と日本円の合計金額候補だけです。購入の真正性確認、会計処理、品目別税額の抽出、金融上の助言は行いません。ルールは確認可能で保守的なものに限定しています。テストデータはすべて架空・匿名です。

## 開発

```bash
swift build
swift test
swift run receipt-parser Tests/JapaneseReceiptParserTests/Fixtures/receipt_ja.txt
```

詳細は[CONTRIBUTING.md](CONTRIBUTING.md)、[SUPPORT.md](SUPPORT.md)、[SECURITY.md](SECURITY.md)、[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)、[CHANGELOG.md](CHANGELOG.md)を参照してください。

## ライセンス

MITライセンスです。[LICENSE](LICENSE)を参照してください。
