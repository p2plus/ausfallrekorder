import Foundation
import RecorderCore
#if os(Linux)
import Glibc
#else
import Darwin
#endif

@main
struct RecorderCLI {
    static var usage: String {
        let commands = """
        ausfallrekorder-cli record [--label WLAN] [--duration 28800] [--interval 15] [--output recording.afr]
        ausfallrekorder-cli report recording.afr [--output report.html]
        ausfallrekorder-cli compare wifi.afr lan.afr [--output comparison.html]
        --language de|en|zh-Hans
        """
        switch Language.current {
        case .german:
            return "Ausfallrekorder — Verbindung messen. Bericht mitnehmen.\n\n" + commands + "\n\nDauer/Intervall in Sekunden. Strg+C speichert und beendet. Standard: 8 Stunden, alle 15 Sekunden. Standby wird nicht verhindert. Prüfziele: Router, Cloudflare, Google, example.com. Messdaten bleiben lokal. Linux benötigt iproute2, iputils-ping und getent."
        case .english:
            return "Ausfallrekorder — Measure your connection. Take the report.\n\n" + commands + "\n\nDuration/interval in seconds. Ctrl+C saves and stops. Default: 8 hours, every 15 seconds. Does not prevent sleep. Targets: router, Cloudflare, Google, example.com. Recordings stay local. Linux needs iproute2, iputils-ping and getent."
        case .simplifiedChinese:
            return "Ausfallrekorder — 测量网络连接，导出实用报告。\n\n" + commands + "\n\n时长和间隔以秒为单位。Ctrl+C 保存并停止。默认记录 8 小时，每 15 秒检查一次。不会阻止系统休眠。测试目标：路由器、Cloudflare、Google、example.com。记录仅保存在本机。Linux 需要 iproute2、iputils-ping 和 getent。"
        }
    }

    static func main() async {
        do { try await execute(Array(CommandLine.arguments.dropFirst())) }
        catch {
            FileHandle.standardError.write(Data((tr("Fehler: %@", error.localizedDescription) + "\n").utf8))
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
        let allowed = command == "record" ? ["--label", "--duration", "--interval", "--output", "--language"] : ["--output", "--language"]
        while i < arguments.count {
            let arg = arguments[i]
            if arg.hasPrefix("--") {
                guard allowed.contains(arg), i + 1 < arguments.count, options[arg] == nil else {
                    throw RecorderError.invalid(tr("Ungültige oder doppelte Option: %@", arg))
                }
                options[arg] = arguments[i + 1]; i += 2
            } else { files.append(arg); i += 1 }
        }
        if let language = options["--language"], Language(rawValue: language) == nil {
            throw RecorderError.invalid("Sprache: de, en oder zh-Hans.")
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
            let label = options["--label"] ?? tr("Mein Rechner")
            guard !label.isEmpty, label.count <= 120 else { throw RecorderError.invalid("Bezeichnung: 1–120 Zeichen.") }
            let output = url(options["--output"] ?? "messung-\(token).afr")
            print(tr("Messung: %@\nStrg+C zum Beenden.", output.path))
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
            print(tr("Gespeichert: %d Messrunden\nBericht: %@", result.samples.count, report.path))
        } else {
            guard files.count == (command == "compare" ? 2 : 1) else {
                throw RecorderError.invalid(tr("Dieser Befehl erwartet %d Messdatei(en).", command == "compare" ? 2 : 1))
            }
            let recording = try Store.load(url(files[0]))
            let other = command == "compare" ? try Store.load(url(files[1])) : nil
            let output = url(options["--output"] ?? "bericht-\(token).html")
            try Data(Report.html(recording, comparing: other).utf8).write(to: output, options: [.withoutOverwriting])
            print(tr("Bericht: %@", output.path))
        }
    }
}
