import Foundation
import ImageIO
import Vision

/// Reads text lines from one image with Apple's on-device Vision framework.
/// No image or recognized text leaves the device through this API.
public struct ImageTextRecognizer: Sendable {
    public enum RecognitionError: Error, Equatable, Sendable {
        case invalidImage
    }

    public init() {}

    /// Recognizes text and returns non-empty lines in visual reading order.
    ///
    /// - Parameters:
    ///   - imageData: JPEG, PNG, HEIC, or another format supported by ImageIO.
    ///   - languages: BCP-47 language tags ordered by preference.
    public func recognizeLines(
        from imageData: Data,
        languages: [String] = ["ja-JP", "en-US"]
    ) async throws -> [String] {
        try await Task.detached(priority: .userInitiated) {
            try Self.recognizeSynchronously(imageData: imageData, languages: languages)
        }.value
    }

    private static func recognizeSynchronously(
        imageData: Data,
        languages: [String]
    ) throws -> [String] {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw RecognitionError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages

        let handler = VNImageRequestHandler(
            cgImage: image,
            orientation: imageOrientation(from: source),
            options: [:]
        )
        try handler.perform([request])

        return (request.results ?? [])
            .sorted(by: isEarlierInReadingOrder)
            .compactMap { $0.topCandidates(1).first?.string }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func isEarlierInReadingOrder(
        _ lhs: VNRecognizedTextObservation,
        _ rhs: VNRecognizedTextObservation
    ) -> Bool {
        let verticalTolerance = 0.02
        let verticalDistance = abs(lhs.boundingBox.midY - rhs.boundingBox.midY)

        if verticalDistance <= verticalTolerance {
            return lhs.boundingBox.minX < rhs.boundingBox.minX
        }

        return lhs.boundingBox.midY > rhs.boundingBox.midY
    }

    private static func imageOrientation(from source: CGImageSource) -> CGImagePropertyOrientation {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let rawValue = (properties?[kCGImagePropertyOrientation] as? UInt32) ?? 1
        return CGImagePropertyOrientation(rawValue: rawValue) ?? .up
    }
}
