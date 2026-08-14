import Foundation
import JapaneseReceiptParser

@main
struct ReceiptParserCommand {
    static func main() async {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            let receipt: Receipt

            if arguments.first == "--image", let path = arguments.dropFirst().first {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let lines = try await ImageTextRecognizer().recognizeLines(from: data)
                receipt = ReceiptParser().parse(lines: lines)
            } else {
                let text = try readText(path: arguments.first)
                receipt = ReceiptParser().parse(lines: text.components(separatedBy: .newlines))
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            FileHandle.standardOutput.write(try encoder.encode(receipt))
            FileHandle.standardOutput.write(Data("\n".utf8))
            FileHandle.standardError.write(
                Data("Review extracted values before saving or using them.\n".utf8)
            )
        } catch {
            FileHandle.standardError.write(Data("receipt-parser: \(error)\n".utf8))
            Foundation.exit(EXIT_FAILURE)
        }
    }

    private static func readText(path: String?) throws -> String {
        if let path {
            return try String(contentsOfFile: path, encoding: .utf8)
        }

        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else {
            throw InputError.notUTF8
        }
        return text
    }

    private enum InputError: Error {
        case notUTF8
    }
}
