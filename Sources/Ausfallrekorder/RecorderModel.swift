#if os(macOS)
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import RecorderCore

@MainActor
final class RecorderModel: ObservableObject {
    @Published var label = tr("Mein Mac")
    @Published var recording: Recording?
    @Published var comparison: Recording?
    @Published var running = false
    @Published var stopping = false
    @Published var error: String?
    @Published var file: URL?
    private var task: Task<Void, Never>?

    func start() {
        guard !running else { return }
        error = nil; comparison = nil
        do {
            let folder = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                     appropriateFor: nil, create: true).appendingPathComponent("Ausfallrekorder")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("messung-\(UUID().uuidString).afr")
            let initial = Recording(label: label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? tr("Mein Mac") : String(label.prefix(120)))
            recording = initial; file = url; running = true; stopping = false
            task = Task { [self] in
                do {
                    let finished = try await Capture.run(initial, at: url) { [self] sample in
                        await MainActor.run { self.recording?.samples.append(sample) }
                    }
                    recording = finished
                } catch { self.error = tr("Messung angehalten: %@", error.localizedDescription) }
                running = false; stopping = false; task = nil
            }
        } catch { self.error = error.localizedDescription }
    }

    func stop() { stopping = true; task?.cancel() }

    func load(comparing: Bool = false) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "afr") ?? .data]
        panel.canChooseDirectories = false
        panel.message = comparing ? tr("Messung des zweiten Geräts auswählen.") : tr("Gespeicherte Messung öffnen.")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let loaded = try Store.load(url)
            if comparing { comparison = loaded }
            else { recording = loaded; comparison = nil; file = url }
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    func export(report: Bool) {
        guard let recording else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = report ? "Ausfallbericht.html" : "Messung.afr"
        panel.allowedContentTypes = report ? [.html] : [UTType(filenameExtension: "afr") ?? .data]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            if report { try Data(Report.html(recording, comparing: comparison).utf8).write(to: url, options: .atomic) }
            else if let file {
                guard file.standardizedFileURL != url.standardizedFileURL else { return }
                try Data(contentsOf: file).write(to: url, options: .atomic)
            }
            error = nil
        } catch { self.error = error.localizedDescription }
    }
}

#endif
