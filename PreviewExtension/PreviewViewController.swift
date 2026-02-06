import Cocoa
import Quartz
import ThorVGSwift

/// Quick Look preview controller for Lottie animations
class PreviewViewController: NSViewController, QLPreviewingController {

    private var animationView: LottieAnimationView?
    private var errorLabel: NSTextField?

    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        animationView?.stop()
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // First, check if this might be a Lottie file
            // For .json files, we do a quick heuristic check
            let ext = url.pathExtension.lowercased()
            if ext == "json" && !LottieFileHandler.isLikelyLottieFile(at: url) {
                // Not a Lottie file - let the system handle it as regular JSON
                DispatchQueue.main.async {
                    handler(LottieFileError.notALottieFile)
                }
                return
            }

            do {
                // Load Lottie (validates format)
                let lottie = try LottieFileHandler.loadLottie(from: url)

                // Create animated view on main thread
                DispatchQueue.main.async {
                    self?.setupAnimationView(with: lottie)
                    handler(nil)
                }

            } catch LottieFileError.notALottieFile {
                // For .json files that aren't Lottie - let system handle
                DispatchQueue.main.async {
                    handler(LottieFileError.notALottieFile)
                }

            } catch {
                DispatchQueue.main.async {
                    self?.showError("Failed to load animation")
                    handler(error)
                }
            }
        }
    }

    private func setupAnimationView(with lottie: Lottie) {
        // Remove any existing views
        animationView?.removeFromSuperview()
        errorLabel?.removeFromSuperview()

        let animView = LottieAnimationView(lottie: lottie)
        animView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animView)

        NSLayoutConstraint.activate([
            animView.topAnchor.constraint(equalTo: view.topAnchor),
            animView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            animView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        self.animationView = animView
        animView.play()
    }

    private func showError(_ message: String) {
        // Remove any existing views
        animationView?.removeFromSuperview()
        errorLabel?.removeFromSuperview()

        let label = NSTextField(labelWithString: message)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = NSColor.secondaryLabelColor
        label.alignment = .center
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])

        self.errorLabel = label
    }
}
