import Foundation
import RecorderCore
#if os(Linux)
import Glibc
#else
import Darwin
#endif

@main
struct RecorderCLI {
    static let usage = """
    Ausfallrekorder — Verbindung messen. Bericht mitnehmen.

    ausfallrekorder-cli record [--label WLAN] [--duration 28800] [--interval 15] [--output messung.afr]
    ausfallrekorder-cli report messung.afr [--output bericht.html]
    ausfallrekorder-cli compare wlan.afr lan.afr [--output vergleich.html]

    Dauer und Intervall in Sekunden. Strg+C beendet die Messung sauber.
    Ohne Optionen: 8 Stunden, alle 15 Sekunden, Dateien im aktuellen Ordner.
    Während der Messung muss der Rechner wach bleiben.
    Prüfziele: Router, Cloudflare, Google, example.com. Messdaten bleiben lokal.
    Linux: iproute2, iputils-ping und getent müssen installiert sein.
    """

    static func main() async {
        do { try await execute(Array(CommandLine.arguments.dropFirst())) }
        catch {
            FileHandle.standardError.write(Data("Fehler: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    static func execute(_ arguments: [String]) async throws {
        guard let command = arguments.first, !["help", "--help", "-h"].contains(command) else {
            print(usage); return
        }
        guard ["record", "report", "compare"].contains(command) else {
            throw RecorderError.invalid("Unbekannter Befehl. Hilfe: ausfallrekorder-cli --help")
        }
        var options: [String: String] = [:]
        var files: [String] = []
        var i = 1
        let allowed = command == "record" ? ["--label", "--duration", "--interval", "--output"] : ["--output"]
        while i < arguments.count {
            let arg = arguments[i]
            if arg.hasPrefix("--") {
                guard allowed.contains(arg), i + 1 < arguments.count, options[arg] == nil else {
                    throw RecorderError.invalid("Ungültige oder doppelte Option: \(arg)")
                }
                options[arg] = arguments[i + 1]; i += 2
            } else { files.append(arg); i += 1 }
        }
        func url(_ path: String) -> URL {
            URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
        }
        let token = String(UUID().uuidString.prefix(8)).lowercased()
        if command == "record" {
            guard files.isEmpty,
                  let duration = Double(options["--duration"] ?? "28800"), duration.isFinite, (1...86_400).contains(duration),
                  let interval = Double(options["--interval"] ?? "15"), interval.isFinite, (5...60).contains(interval) else {
                throw RecorderError.invalid("Messdauer: 1–86400 s. Intervall: 5–60 s. Keine zusätzlichen Dateinamen.")
            }
            let label = options["--label"] ?? "Mein Rechner"
            guard !label.isEmpty, label.count <= 120 else { throw RecorderError.invalid("Bezeichnung: 1–120 Zeichen.") }
            let output = url(options["--output"] ?? "messung-\(token).afr")
            print("Messung: \(output.path)\nStrg+C zum Beenden.")
            let task = Task {
                try await Capture.run(Recording(label: label, interval: interval), at: output, seconds: duration) { sample in
                    print("\(ISO8601DateFormatter().string(from: sample.at))  \(sample.health.title)")
                }
            }
            signal(SIGINT, SIG_IGN)
            signal(SIGTERM, SIG_IGN)
            let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .global())
            let terminate = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .global())
            interrupt.setEventHandler { task.cancel() }
            terminate.setEventHandler { task.cancel() }
            interrupt.resume(); terminate.resume()
            defer { interrupt.cancel(); terminate.cancel() }
            let result = try await task.value
            let report = output.deletingPathExtension().appendingPathExtension("html")
            try Data(Report.html(result).utf8).write(to: report, options: [.withoutOverwriting])
            print("Gespeichert: \(result.samples.count) Messrunden\nBericht: \(report.path)")
        } else {
            guard files.count == (command == "compare" ? 2 : 1) else {
                throw RecorderError.invalid("\(command) erwartet \(command == "compare" ? "zwei Messdateien" : "eine Messdatei").")
            }
            let recording = try Store.load(url(files[0]))
            let other = command == "compare" ? try Store.load(url(files[1])) : nil
            let output = url(options["--output"] ?? "bericht-\(token).html")
            try Data(Report.html(recording, comparing: other).utf8).write(to: output, options: [.withoutOverwriting])
            print("Bericht: \(output.path)")
        }
    }
}
