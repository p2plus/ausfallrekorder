#if os(macOS)
import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = RecorderModel()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var terminationSignal: DispatchSourceSignal?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "Ausfallrekorder")
        item.button?.toolTip = "Ausfallrekorder"
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        statusItem = item
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: RecorderPopover(model: model))
        popover.contentSize = NSSize(width: 350, height: 320)
        DispatchQueue.main.async { [weak self] in self?.togglePopover() }
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler { Task { @MainActor in NSApplication.shared.terminate(nil) } }
        source.resume()
        terminationSignal = source
    }
    @objc func togglePopover() {
        if popover.isShown { popover.performClose(nil) }
        else if let button = statusItem?.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !popover.isShown { togglePopover() }
        return true
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard model.running else { return .terminateNow }
        model.stop()
        Task { @MainActor in
            while model.running { try? await Task.sleep(for: .milliseconds(50)) }
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}

@main
struct AusfallrekorderApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        if Preview.renderIfRequested() { return }
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}
#else
import Foundation
@main
struct MacOnly {
    static func main() { print("Unter Linux bitte ausfallrekorder-cli verwenden.") }
}
#endif
