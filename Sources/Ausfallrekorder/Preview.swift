#if os(macOS)
import AppKit
import SwiftUI
import RecorderCore

/// Reproducible documentation images, rendered from the app's actual view.
@MainActor
enum Preview {
    static func renderIfRequested() -> Bool {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--render-preview"), i + 1 < args.count else { return false }
        do {
            NSApp.setActivationPolicy(.prohibited)
            let model = RecorderModel()
            if let index = args.firstIndex(of: "--recording"), index + 1 < args.count {
                model.recording = try Store.load(URL(fileURLWithPath: args[index + 1]))
                model.running = args.contains("--running")
            }
            let view = NSHostingView(rootView: RecorderPopover(model: model)
                .environment(\.colorScheme, .light).background(Color.white))
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 350, height: 500),
                                  styleMask: .borderless, backing: .buffered, defer: false)
            window.contentView = view
            view.layoutSubtreeIfNeeded()
            let size = view.fittingSize
            window.setContentSize(size)
            view.frame = NSRect(origin: .zero, size: size)
            view.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            guard let image = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                throw RecorderError.invalid("Could not render preview")
            }
            view.cacheDisplay(in: view.bounds, to: image)
            guard let data = image.representation(using: .png, properties: [:]) else {
                throw RecorderError.invalid("Could not encode preview")
            }
            try data.write(to: URL(fileURLWithPath: args[i + 1]))
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            exit(1)
        }
        return true
    }
}
#endif
