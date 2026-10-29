#if os(macOS)
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import RecorderCore

@MainActor
final class RecorderModel: ObservableObject {
    @Published var label = "Mein Mac"
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
            let initial = Recording(label: label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Mein Mac" : String(label.prefix(120)))
            recording = initial; file = url; running = true; stopping = false
            task = Task { [self] in
                do {
                    let finished = try await Capture.run(initial, at: url) { [self] sample in
                        await MainActor.run { self.recording?.samples.append(sample) }
                    }
                    recording = finished
                } catch { self.error = "Messung angehalten: \(error.localizedDescription)" }
                running = false; stopping = false; task = nil
            }
        } catch { self.error = error.localizedDescription }
    }

    func stop() { stopping = true; task?.cancel() }

    func load(comparing: Bool = false) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "afr") ?? .data]
        panel.canChooseDirectories = false
        panel.message = comparing ? "Messung des zweiten Geräts auswählen." : "Gespeicherte Messung öffnen."
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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var model: RecorderModel?
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let model = Self.model, model.running else { return .terminateNow }
        model.stop()
        Task { @MainActor in
            while model.running { try? await Task.sleep(for: .milliseconds(50)) }
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}

@main
struct AusfallrekorderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = RecorderModel()
    var body: some Scene {
        WindowGroup {
            RecorderView(model: model)
                .onAppear { AppDelegate.model = model }
        }
        .defaultSize(width: 760, height: 640)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}

struct RecorderView: View {
    @ObservedObject var model: RecorderModel
    private var samples: [Sample] { model.recording?.samples ?? [] }
    private var last: Sample? { samples.last }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ausfallrekorder").font(.largeTitle.bold())
                    Text("Verbindung messen. Bericht mitnehmen.").foregroundStyle(.secondary)
                }
                Spacer()
                if model.running {
                    Button(model.stopping ? "Wird beendet …" : "Messung stoppen", action: model.stop)
                        .disabled(model.stopping)
                } else {
                    Button("Messung starten", action: model.start).buttonStyle(.borderedProminent)
                }
            }
            HStack {
                TextField("Gerätebezeichnung", text: $model.label).textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220).disabled(model.running)
                Text(model.running ? "Alle 15 Sekunden · endet nach 8 Stunden" : "Lokal gespeichert · kein Konto")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 14) {
                Circle().fill(last == nil ? .gray : last?.health == .online ? .green : .orange).frame(width: 13, height: 13)
                VStack(alignment: .leading, spacing: 5) {
                    Text(last?.health.title ?? (model.running ? "Erste Prüfung läuft …" : "Bereit, wenn du es bist.")).font(.title3.weight(.semibold))
                    if let last {
                        Text("Letzte Prüfung \(last.at.formatted(date: .omitted, time: .standard)) · \(last.network)")
                            .font(.caption).foregroundStyle(.secondary)
                    } else { Text("Router, Internet, DNS und HTTPS.").font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
            }
            .padding(18).background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))

            if let recording = model.recording {
                HStack(spacing: 30) {
                    metric("Messrunden", "\(samples.count)")
                    metric("Auffälligkeiten", "\(Analysis.incidents(recording).count)")
                    metric("Beobachtet", Report.seconds(Analysis.observedSeconds(recording)))
                }
                if let comparison = model.comparison {
                    Text("Vergleich: \(comparison.label) · \(Report.seconds(Analysis.simultaneousSeconds(recording, comparison))) gemeinsame Fehlerfenster")
                        .font(.callout)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Letzte Prüfungen").font(.headline)
                List(Array(samples.suffix(100).reversed().enumerated()), id: \.offset) { _, sample in
                    HStack {
                        Text(sample.at, style: .time).monospacedDigit().foregroundStyle(.secondary)
                        Text(sample.health.title)
                        Spacer()
                        Image(systemName: sample.health == .online ? "checkmark.circle" : "exclamationmark.circle")
                            .foregroundStyle(sample.health == .online ? .green : .orange)
                    }.font(.callout).padding(.vertical, 3)
                }.listStyle(.bordered(alternatesRowBackgrounds: true)).frame(minHeight: 140)
            }
            if let error = model.error { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            HStack {
                Button("Messung öffnen …") { model.load() }.disabled(model.running)
                Button("Vergleichen …") { model.load(comparing: true) }.disabled(model.recording == nil || model.running)
                Spacer()
                Menu("Exportieren") {
                    Button("Bericht als HTML …") { model.export(report: true) }
                    Button("Messdatei …") { model.export(report: false) }
                }.disabled(model.recording == nil || model.running)
            }
            Text("Standby und die Zeit zwischen Prüfungen sind unbeobachtet. Ein Fehler ist ein Hinweis, kein Beweis gegen den Anbieter. Prüfziele: Cloudflare, Google und example.com.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(28).frame(minWidth: 700, minHeight: 620)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.title2.monospacedDigit().weight(.semibold))
            Text(label).font(.caption).foregroundStyle(.secondary)
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
