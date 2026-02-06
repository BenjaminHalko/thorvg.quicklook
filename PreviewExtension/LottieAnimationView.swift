import AppKit
import CoreMedia
import ThorVGSwift

/// NSView that renders animated Lottie content using CVDisplayLink
class LottieAnimationView: NSView {
    private let lottie: Lottie
    private var displayLink: CVDisplayLink?
    private var currentFrame: Float = 0
    private var renderWidth: Int = 0
    private var renderHeight: Int = 0
    private var lastRenderTime: CFTimeInterval = 0
    private let frameRate: Double

    init(lottie: Lottie) {
        self.lottie = lottie
        // Get frame rate from Lottie duration and frame count
        let frameDuration = lottie.frameDuration.seconds;
        self.frameRate = frameDuration > 0 ? 1.0 / frameDuration : 30.0
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.contentsGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool {
        return true
    }

    override func layout() {
        super.layout()
        updateRenderSize()
        renderFrame()
    }

    private func updateRenderSize() {
        let viewSize = bounds.size
        guard viewSize.width > 0 && viewSize.height > 0 else { return }

        let frameSize = lottie.frameSize
        guard frameSize.width > 0 && frameSize.height > 0 else { return }

        // Account for retina displays
        let backingScale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1.0

        let scale = min(viewSize.width / frameSize.width, viewSize.height / frameSize.height)
        renderWidth = Int(ceil(frameSize.width * scale * backingScale))
        renderHeight = Int(ceil(frameSize.height * scale * backingScale))
    }

    func play() {
        guard displayLink == nil else { return }
        setupDisplayLink()
    }

    func stop() {
        if let link = displayLink {
            CVDisplayLinkStop(link)
            displayLink = nil
        }
    }

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let displayLink = link else { return }

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, context in
            let view = Unmanaged<LottieAnimationView>.fromOpaque(context!).takeUnretainedValue()
            let currentTime = CFAbsoluteTimeGetCurrent()

            let timeSinceLastFrame = currentTime - view.lastRenderTime
            let targetInterval = 1.0 / view.frameRate

            if timeSinceLastFrame >= targetInterval {
                DispatchQueue.main.async {
                    view.advanceFrame()
                }
                view.lastRenderTime = currentTime
            }

            return kCVReturnSuccess
        }

        let pointer = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink, callback, pointer)
        CVDisplayLinkStart(displayLink)
        self.displayLink = displayLink
        lastRenderTime = CFAbsoluteTimeGetCurrent()
    }

    private func advanceFrame() {
        currentFrame += 1
        if currentFrame >= lottie.numberOfFrames {
            currentFrame = 0
        }
        renderFrame()
    }

    private func renderFrame() {
        guard renderWidth > 0, renderHeight > 0 else { return }

        let pixelCount = renderWidth * renderHeight
        var buffer = [UInt32](repeating: 0, count: pixelCount)

        buffer.withUnsafeMutableBufferPointer { bufferPointer in
            guard let baseAddress = bufferPointer.baseAddress else { return }

            let renderer = LottieRenderer(
                lottie,
                size: CGSize(width: renderWidth, height: renderHeight),
                buffer: baseAddress,
                stride: renderWidth,
                pixelFormat: .argb
            )

            let contentRect = CGRect(origin: .zero, size: CGSize(width: renderWidth, height: renderHeight))

            do {
                try renderer.render(frameIndex: currentFrame, contentRect: contentRect)
            } catch {
                return
            }
        }

        updateLayer(with: buffer)
    }

    private func updateLayer(with buffer: [UInt32]) {
        let data = buffer.withUnsafeBytes { Data($0) }

        guard let provider = CGDataProvider(data: data as CFData),
              let cgImage = CGImage(
                width: renderWidth,
                height: renderHeight,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: renderWidth * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.contents = cgImage
        CATransaction.commit()
    }

    deinit {
        stop()
    }
}
