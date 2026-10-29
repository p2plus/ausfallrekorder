import Foundation

public enum Language: String, CaseIterable, Sendable {
    case german = "de", english = "en", simplifiedChinese = "zh-Hans"

    public static func resolve(_ identifier: String) -> Language {
        let value = identifier.lowercased().replacingOccurrences(of: "_", with: "-")
        if value.hasPrefix("de") { return .german }
        if value == "zh" || value.hasPrefix("zh-hans") || value.hasPrefix("zh-cn") || value.hasPrefix("zh-sg") {
            return .simplifiedChinese
        }
        return .english
    }

    public static let current: Language = {
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--language"), i + 1 < args.count {
            return resolve(args[i + 1])
        }
        return resolve(ProcessInfo.processInfo.environment["AUSFALLREKORDER_LANGUAGE"]
                       ?? Locale.preferredLanguages.first ?? "en")
    }()
}

public func tr(_ source: String, _ arguments: CVarArg...) -> String {
    L.text(source, arguments: arguments)
}

public enum L {
    public static func text(_ source: String, language: Language = .current, arguments: [CVarArg] = []) -> String {
        let index = language == .english ? 0 : 1
        let template = language == .german ? source : entries[source]?[index] ?? source
        return arguments.isEmpty ? template : String(format: template, locale: Locale(identifier: language.rawValue), arguments: arguments)
    }

    // German source key → English, Simplified Chinese. Kept in the core so the
    // standalone Linux binary needs no resource bundle beside it.
    static let entries: [String: [String]] = [
        "Verbindung erreichbar": ["Connection reachable", "连接正常"],
        "Router und Internet antworten nicht": ["Router and internet checks failed", "路由器和互联网检查均失败"],
        "Router antwortet, Internetprüfung fehlgeschlagen": ["Router responds, internet check failed", "路由器正常，互联网检查失败"],
        "IP erreichbar, DNS-/HTTPS-Prüfung fehlgeschlagen": ["IP reachable, DNS/HTTPS check failed", "IP 可达，DNS/HTTPS 检查失败"],
        "Verbindung nicht bestätigt": ["Connection not confirmed", "无法确认连接状态"],
        "MISST": ["RECORDING", "记录中"], "PAUSIERT": ["PAUSED", "已暂停"],
        "Erste Prüfung läuft …": ["First check in progress …", "正在进行首次检查…"],
        "Bereit, wenn du es bist.": ["Ready when you are.", "随时可以开始。"],
        "Router, Internet, DNS und HTTPS.": ["Router, internet, DNS and HTTPS.", "检查路由器、互联网、DNS 和 HTTPS。"],
        "Zuletzt %@ · %@": ["Last check %@ · %@", "上次检查 %@ · %@"],
        "Router": ["Router", "路由器"], "Internet": ["Internet", "互联网"],
        "Messung stoppen": ["Stop recording", "停止记录"],
        "Wird beendet …": ["Stopping …", "正在停止…"],
        "Messung starten": ["Start recording", "开始记录"],
        "%d Prüfungen": ["%d checks", "%d 次检查"],
        "%d Auffälligkeiten": ["%d incidents", "%d 次异常"],
        "Alle 15 Sekunden · endet nach 8 Stunden": ["Every 15 seconds · stops after 8 hours", "每 15 秒检查一次 · 8 小时后停止"],
        "Gerätebezeichnung": ["Device label", "设备名称"],
        "Letzte Prüfungen": ["Recent checks", "最近的检查"],
        "Erreichbar": ["Reachable", "可达"], "Auffällig": ["Check failed", "检查失败"],
        "Vergleich geladen: %@": ["Comparison loaded: %@", "已加载对比：%@"],
        "Exportieren": ["Export", "导出"], "Öffnen": ["Open", "打开"],
        "Bericht als HTML …": ["HTML report …", "HTML 报告…"],
        "Messdatei exportieren …": ["Recording file …", "记录文件…"],
        "Messung öffnen …": ["Open recording …", "打开记录…"],
        "Mit Messung vergleichen …": ["Compare recordings …", "对比记录…"],
        "Beenden": ["Quit", "退出"], "Mein Mac": ["My Mac", "我的 Mac"],
        "Mein Rechner": ["My computer", "我的电脑"],
        "Messung angehalten: %@": ["Recording stopped: %@", "记录已停止：%@"],
        "Messung des zweiten Geräts auswählen.": ["Choose the other device's recording.", "请选择另一台设备的记录。"],
        "Gespeicherte Messung öffnen.": ["Open a saved recording.", "打开已保存的记录。"],
        "Vergleich mit %@": ["Comparison with %@", "与 %@ 对比"],
        "Keine gemeinsamen Messfenster. Ein zeitlicher Vergleich ist nicht möglich.": ["No shared observation windows. A time comparison is not possible.", "没有重叠的观测时段，无法进行时间对比。"],
        "%@ gleichzeitig beobachtet. Davon %@ mit fehlgeschlagener Verbindungsprüfung auf beiden Geräten.": ["%@ observed simultaneously. Both devices failed their connection checks during %@ of those windows.", "同时观测了 %@，其中两台设备的连接检查均失败的时段共 %@。"],
        "Die Geräteuhren müssen stimmen. Gemeinsame Fehler grenzen ein Problem ein, beweisen aber keine Ursache.": ["Device clocks must agree. Shared failures help narrow down a problem; they do not prove its cause.", "两台设备的时钟必须同步。共同失败有助于缩小问题范围，但不能证明原因。"],
        "Keine Messwerte": ["No measurements", "暂无测量数据"],
        "%d Messrunden · %d Auffälligkeiten": ["%d checks · %d incidents", "%d 次检查 · %d 次异常"],
        "AUSFALLREKORDER · LOKALER MESSBERICHT": ["AUSFALLREKORDER · LOCAL CONNECTION REPORT", "AUSFALLREKORDER · 本地连接报告"],
        "Beginn": ["Started", "开始时间"], "Ende": ["Ended", "结束时间"],
        "Nicht abgeschlossen / noch aktiv": ["Unfinished / still recording", "未完成 / 仍在记录"],
        "Tatsächliche Messfenster": ["Actual observation windows", "实际观测时段"],
        "Fenster mit fehlgeschlagener Verbindungsprüfung": ["Windows with failed connection checks", "连接检查失败的观测时段"],
        "Es wird alle %d Sekunden geprüft. Zwischen den Prüfungen und während Standby gibt es keine Beobachtung. Die Liste fasst aufeinanderfolgende Fehler zusammen; ihre Zeitspanne ist keine lückenlos gemessene Ausfalldauer. Kurze Abbrüche können unbemerkt bleiben.": ["Checks run every %d seconds. Time between checks and sleep is unobserved. Consecutive failures are grouped; their span is not a continuously measured outage. Short interruptions may go unnoticed.", "每 %d 秒检查一次。检查之间以及休眠期间没有观测数据。连续失败会合并显示，但其时间跨度不代表持续测得的断网时长。短暂中断可能无法发现。"],
        "Auffälligkeiten": ["Incidents", "异常记录"],
        "Keine fehlgeschlagene Verbindungsprüfung aufgezeichnet.": ["No failed connection checks recorded.", "未记录到连接检查失败。"],
        "Erstmals (UTC)": ["First seen (UTC)", "首次出现 (UTC)"],
        "Zuletzt (UTC)": ["Last seen (UTC)", "最后出现 (UTC)"],
        "Beobachtung": ["Observation", "观测结果"],
        "Letzte Prüfdetails": ["Latest check details", "最近检查的详细信息"],
        "Was das bedeutet": ["What this means", "结果说明"],
        "HTTPS erfolgreich bestätigt die Erreichbarkeit eines Testdienstes. Ping kann durch Firewalls blockiert werden. DNS kann aus dem Systemcache beantwortet werden. Ein einzelner Testdienst kann selbst ausfallen. Die Messung beweist weder einen Fehler beim Anbieter noch die Erreichbarkeit aller Internetdienste.": ["Successful HTTPS confirms one test service is reachable. Firewalls can block ping. DNS may use the system cache. A test service can fail too. These measurements neither prove an ISP fault nor confirm every internet service is reachable.", "HTTPS 成功说明某个测试服务可达。防火墙可能拦截 Ping，DNS 可能使用系统缓存，测试服务自身也可能故障。这些测量既不能证明运营商存在故障，也不能确认所有互联网服务都可达。"],
        "Keine Konten, keine hochgeladenen Messdaten. Die Prüfungen kontaktieren Cloudflare, Google und example.com. Dieser Bericht enthält die gewählte Gerätebezeichnung und technische Netzwerkdetails.": ["No accounts or uploaded recordings. Checks contact Cloudflare, Google and example.com. This report includes the chosen device label and technical network details.", "无需账号，不上传记录。检查会连接 Cloudflare、Google 和 example.com。本报告包含您设置的设备名称和技术性网络信息。"],
        "Fehler: %@": ["Error: %@", "错误：%@"],
        "Unbekannter Befehl. Hilfe: ausfallrekorder-cli --help": ["Unknown command. Help: ausfallrekorder-cli --help", "未知命令。帮助：ausfallrekorder-cli --help"],
        "Ungültige oder doppelte Option: %@": ["Invalid or duplicate option: %@", "无效或重复的选项：%@"],
        "Messdauer: 1–86400 s. Intervall: 5–60 s. Keine zusätzlichen Dateinamen.": ["Duration: 1–86400 s. Interval: 5–60 s. No extra filenames.", "记录时长：1–86400 秒。间隔：5–60 秒。请勿提供额外文件名。"],
        "Bezeichnung: 1–120 Zeichen.": ["Label: 1–120 characters.", "名称长度：1–120 个字符。"],
        "Messung: %@\nStrg+C zum Beenden.": ["Recording: %@\nCtrl+C to stop.", "记录文件：%@\n按 Ctrl+C 停止。"],
        "Gespeichert: %d Messrunden\nBericht: %@": ["Saved: %d checks\nReport: %@", "已保存：%d 次检查\n报告：%@"],
        "Bericht: %@": ["Report: %@", "报告：%@"],
        "Dieser Befehl erwartet %d Messdatei(en).": ["This command expects %d recording file(s).", "此命令需要 %d 个记录文件。"],
        "Sprache: de, en oder zh-Hans.": ["Language: de, en or zh-Hans.", "语言：de、en 或 zh-Hans。"],
        "Die Datei existiert bereits. Bitte einen neuen Namen wählen.": ["The file already exists. Choose another name.", "文件已存在，请使用其他名称。"],
        "Die Messdatei ist größer als 64 MB.": ["The recording exceeds 64 MB.", "记录文件超过 64 MB。"],
        "Keine vollständige Messdatei.": ["No complete recording header found.", "未找到完整的记录文件头。"],
        "Unbekanntes oder ungültiges Messformat.": ["Unknown or invalid recording format.", "未知或无效的记录格式。"],
        "Daten nach Messende.": ["Unexpected data after the recording ended.", "记录结束后存在异常数据。"],
        "Ungültige oder falsch sortierte Messwerte.": ["Invalid or out-of-order measurements.", "测量数据无效或顺序错误。"],
        "Ungültiger Eintrag in der Messdatei.": ["Invalid entry in the recording file.", "记录文件中的条目无效。"],
        "Intervall: 1–60 Sekunden. Messdauer: 1–86400 Sekunden.": ["Interval: 1–60 seconds. Duration: 1–86400 seconds.", "间隔：1–60 秒。记录时长：1–86400 秒。"],
        "Programm fehlt: %@": ["Missing program: %@", "缺少程序：%@"],
        "Abgebrochen": ["Cancelled", "已取消"], "Zeitlimit": ["Timed out", "超时"],
        "antwortet": ["responds", "有响应"], "Kein Ziel": ["No target", "无目标"],
        "Kein IPv4-Standardrouter gefunden": ["No IPv4 default gateway found", "未找到 IPv4 默认网关"],
        "Interface": ["Interface", "网络接口"],
        "Routeradresse": ["Gateway address", "网关地址"],
        "DNS example.com": ["DNS example.com", "DNS example.com"],
        "Cloudflare IP": ["Cloudflare IP", "Cloudflare IP"], "Google IP": ["Google IP", "Google IP"],
        "aufgelöst (Systemcache möglich)": ["resolved (may use system cache)", "已解析（可能使用系统缓存）"],
        "example.com erreichbar": ["example.com reachable", "example.com 可达"],
        "example.com nicht bestätigt": ["example.com not confirmed", "无法确认 example.com 可达"],
        "unbekannt": ["unknown", "未知"], "kein IPv4-Router": ["no IPv4 gateway", "无 IPv4 网关"]
    ]
}
