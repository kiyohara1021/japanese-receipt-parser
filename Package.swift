// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JapaneseReceiptParser",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "JapaneseReceiptParser", targets: ["JapaneseReceiptParser"]),
        .executable(name: "receipt-parser", targets: ["ReceiptParserCLI"]),
    ],
    targets: [
        .target(name: "JapaneseReceiptParser"),
        .executableTarget(
            name: "ReceiptParserCLI",
            dependencies: ["JapaneseReceiptParser"]
        ),
        .testTarget(
            name: "JapaneseReceiptParserTests",
            dependencies: ["JapaneseReceiptParser"],
            resources: [.copy("Fixtures")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
