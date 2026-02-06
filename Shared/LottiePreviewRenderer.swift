import Foundation
import AppKit
import ThorVGSwift

/// Renders Lottie animations to static images for thumbnails and previews
class LottiePreviewRenderer {

    /// Render a specific frame of a Lottie animation to NSImage
    static func renderFrame(
        lottie: Lottie,
        frameIndex: Float = 0,
        maxSize: CGSize = CGSize(width: 800, height: 800)
    ) -> NSImage? {
        let frameSize = lottie.frameSize
        guard frameSize.width > 0 && frameSize.height > 0 else {
            return nil
        }

        let scale = min(maxSize.width / frameSize.width, maxSize.height / frameSize.height)
        let width = Int(ceil(frameSize.width * scale))
        let height = Int(ceil(frameSize.height * scale))

        guard width > 0 && height > 0 else {
            return nil
        }

        var buffer = [UInt32](repeating: 0, count: width * height)

        let success = buffer.withUnsafeMutableBufferPointer { bufferPointer -> Bool in
            guard let baseAddress = bufferPointer.baseAddress else { return false }

            let renderer = LottieRenderer(
                lottie,
                size: CGSize(width: width, height: height),
                buffer: baseAddress,
                stride: width,
                pixelFormat: .argb
            )

            let contentRect = CGRect(origin: .zero, size: CGSize(width: width, height: height))

            do {
                try renderer.render(frameIndex: frameIndex, contentRect: contentRect)
                return true
            } catch {
                return false
            }
        }

        guard success else { return nil }

        return createNSImage(from: buffer, width: width, height: height)
    }

    private static func createNSImage(from buffer: [UInt32], width: Int, height: Int) -> NSImage? {
        let data = buffer.withUnsafeBytes { Data($0) }

        guard let provider = CGDataProvider(data: data as CFData),
              let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
}
