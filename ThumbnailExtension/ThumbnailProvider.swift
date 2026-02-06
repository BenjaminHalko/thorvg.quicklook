import AppKit
import QuickLookThumbnailing
import ThorVGSwift

class ThumbnailProvider: QLThumbnailProvider {

    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let url = request.fileURL
        let maxSize = request.maximumSize

        // Quick check for .json files - skip if not a Lottie animation
        if url.pathExtension.lowercased() == "json"
            && !LottieFileHandler.isLikelyLottieFile(at: url)
        {
            handler(nil, nil)
            return
        }

        do {
            let lottie = try LottieFileHandler.loadLottie(from: url)

            let frameSize = lottie.frameSize
            guard frameSize.width > 0 && frameSize.height > 0 else {
                handler(nil, LottieFileError.invalidFormat)
                return
            }

            let scale =
                min(maxSize.width / frameSize.width, maxSize.height / frameSize.height)

            let thumbnailSize = CGSize(
                width: ceil(frameSize.width * scale),
                height: ceil(frameSize.height * scale)
            )

            let pixelSize = CGSize(
                width: ceil(frameSize.width * scale * request.scale),
                height: ceil(frameSize.height * scale * request.scale)
            )

            guard
                let image = LottiePreviewRenderer.renderFrame(
                    lottie: lottie,
                    frameIndex: 0,
                    maxSize: pixelSize
                ),
                let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
            else {
                handler(nil, nil)
                return
            }

            let requestScale = request.scale
            let reply = QLThumbnailReply(contextSize: thumbnailSize) { context -> Bool in

                let pixelRect = CGRect(
                    x: 0,
                    y: 0,
                    width: pixelSize.width,
                    height: pixelSize.height
                )

                // Fill with white background
                context.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
                context.fill(pixelRect)

                // Draw the image to fill the entire context
                context.draw(cgImage, in: pixelRect)

                return true
            }

            handler(reply, nil)

        } catch {
            // Not a valid Lottie file - let system use default icon
            handler(nil, error)
        }
    }
}
