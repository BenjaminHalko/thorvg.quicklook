import Foundation
import ThorVGSwift

/// Errors that can occur when loading Lottie files
enum LottieFileError: Error, LocalizedError {
    case notALottieFile
    case invalidFormat
    case loadFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notALottieFile:
            return "The file is not a valid Lottie animation"
        case .invalidFormat:
            return "Unsupported file format"
        case .loadFailed(let error):
            return "Failed to load animation: \(error.localizedDescription)"
        }
    }
}

/// Handles loading and validation of Lottie animation files
class LottieFileHandler {

    /// Load Lottie from .json or .lot file
    /// - Parameter url: The file URL to load
    /// - Returns: A loaded Lottie object
    /// - Throws: LottieFileError if loading fails
    static func loadLottie(from url: URL) throws -> Lottie {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "json", "lot":
            // Both are JSON-based, ThorVG validates on load
            do {
                return try Lottie(path: url.path)
            } catch {
                // ThorVG throws if the file is not a valid Lottie
                throw LottieFileError.notALottieFile
            }
        default:
            throw LottieFileError.invalidFormat
        }
    }

    /// Quick check if a file might be a Lottie animation based on content
    /// This is a heuristic check for .json files that might not be Lottie
    /// - Parameter url: The file URL to check
    /// - Returns: true if the file appears to be a Lottie animation
    static func isLikelyLottieFile(at url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()

        // .lot files are always Lottie
        if ext == "lot" {
            return true
        }

        // For .json files, do a quick content check
        if ext == "json" {
            guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
                  let content = String(data: data.prefix(2048), encoding: .utf8) else {
                return false
            }

            // Lottie files typically have these keys near the start
            let lottieIndicators = ["\"v\":", "\"fr\":", "\"ip\":", "\"op\":", "\"w\":", "\"h\":", "\"layers\""]
            let matchCount = lottieIndicators.filter { content.contains($0) }.count

            // If we find at least 3 Lottie-specific keys, it's likely a Lottie file
            return matchCount >= 3
        }

        return false
    }
}
