import AppKit
import SwiftUI

@main
struct ThorVGQuickLookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let appURL = Bundle.main.bundleURL
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        let isInApplications = appURL.path.hasPrefix(applicationsURL.path)

        if isInApplications {
            showInstalledAlert()
        } else {
            showMoveToApplicationsAlert(appURL: appURL)
        }
    }

    private func showInstalledAlert() {
        let alert = NSAlert()
        alert.messageText = "ThorVG QuickLook Installed"
        alert.informativeText =
            "The Lottie preview extension is now active. You can preview Lottie files in Finder using Quick Look."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()

        NSApplication.shared.terminate(nil)
    }

    private func showMoveToApplicationsAlert(appURL: URL) {
        let alert = NSAlert()
        alert.messageText = "Move to Applications?"
        alert.informativeText =
            "ThorVG QuickLook needs to be in your Applications folder to work properly. Would you like to move it there now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            moveToApplications(from: appURL)
        } else {
            NSApplication.shared.terminate(nil)
        }
    }

    private func moveToApplications(from sourceURL: URL) {
        let destinationURL = URL(fileURLWithPath: "/Applications/ThorVGQuickLook.app")

        do {
            // Remove existing app if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // Move to Applications
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)

            // Launch the new copy
            NSWorkspace.shared.open(destinationURL)

            // Quit this instance
            NSApplication.shared.terminate(nil)

        } catch {
            let errorAlert = NSAlert()
            errorAlert.messageText = "Could not move to Applications"
            errorAlert.informativeText =
                "Please move the app manually to your Applications folder. Error: \(error.localizedDescription)"
            errorAlert.alertStyle = .warning
            errorAlert.addButton(withTitle: "OK")
            errorAlert.runModal()

            NSApplication.shared.terminate(nil)
        }
    }
}
