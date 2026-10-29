import Foundation

public enum Report {
    public static func html(_ recording: Recording, comparing: Recording? = nil) -> String {
        let incidents = Analysis.incidents(recording)
        let formatter = ISO8601DateFormatter()
        let date: (Date) -> String = { formatter.string(from: $0) }
        var comparison = ""
        if let other = comparing {
            let common = Analysis.sharedObservationSeconds(recording, other)
            comparison = "<h2>Vergleich mit \(escape(other.label))</h2>"
            if common == 0 {
                comparison += "<p>Keine gemeinsamen Messfenster. Ein zeitlicher Vergleich ist nicht möglich.</p>"
            } else {
                comparison += "<p>\(seconds(common)) gleichzeitig beobachtet. Davon \(seconds(Analysis.simultaneousSeconds(recording, other))) mit fehlgeschlagener Verbindungsprüfung auf beiden Geräten.</p>"
            }
            comparison += "<p>Die Geräteuhren müssen stimmen. Gemeinsame Fehler grenzen ein Problem ein, beweisen aber keine Ursache.</p>"
        }
        let rows = incidents.map { incident in
            "<tr><td>\(date(incident.start))</td><td>\(date(incident.end))</td><td>\(escape(incident.health.title))</td></tr>"
        }.joined()
        let status = recording.samples.isEmpty ? "Keine Messwerte" : "\(recording.samples.count) Messrunden · \(incidents.count) Auffälligkeiten"
        let latest = recording.samples.last
        let details = latest?.details.sorted(by: { $0.key < $1.key }).map {
            "<li><strong>\(escape($0.key)):</strong> \(escape($0.value))</li>"
        }.joined() ?? ""
        return """
        <!doctype html><html lang="de"><meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'">
        <title>Ausfallrekorder · \(escape(recording.label))</title>
        <style>
        :root{color-scheme:light dark}body{font:16px/1.6 system-ui,sans-serif;max-width:1000px;margin:48px auto;padding:0 24px}
        h1{font-size:36px;letter-spacing:-1px;margin-bottom:0}h2{margin-top:36px}p{max-width:78ch}
        .muted{opacity:.65}.stats{padding:20px;border:1px solid #8885;border-radius:12px}
        table{border-collapse:collapse;width:100%;font-size:14px}td,th{text-align:left;padding:12px 8px;border-bottom:1px solid #8885}
        @media print{body{margin:0;font-size:11pt}tr{break-inside:avoid}}
        </style><body>
        <p class="muted">AUSFALLREKORDER · LOKALER MESSBERICHT</p>
        <h1>\(escape(recording.label))</h1>
        <p>Beginn: \(date(recording.started))<br>Ende: \(recording.ended.map(date) ?? "Nicht abgeschlossen / noch aktiv")</p>
        <div class="stats"><strong>\(status)</strong><br>
        Tatsächliche Messfenster: \(seconds(Analysis.observedSeconds(recording)))<br>
        Fenster mit fehlgeschlagener Verbindungsprüfung: \(seconds(Analysis.failedSeconds(recording)))</div>
        <p>Es wird alle \(Int(recording.interval)) Sekunden geprüft. Zwischen den Prüfungen und während Standby gibt es keine Beobachtung. Die Liste fasst aufeinanderfolgende Fehler zusammen; ihre Zeitspanne ist keine lückenlos gemessene Ausfalldauer. Kurze Abbrüche können unbemerkt bleiben.</p>
        \(comparison)
        <h2>Auffälligkeiten</h2>
        \(incidents.isEmpty ? "<p>Keine fehlgeschlagene Verbindungsprüfung aufgezeichnet.</p>" : "<table><thead><tr><th>Erstmals (UTC)</th><th>Zuletzt (UTC)</th><th>Beobachtung</th></tr></thead><tbody>\(rows)</tbody></table>")
        <h2>Letzte Prüfdetails</h2><ul>\(details)</ul>
        <h2>Was das bedeutet</h2>
        <p>HTTPS erfolgreich bestätigt die Erreichbarkeit eines Testdienstes. Ping kann durch Firewalls blockiert werden. DNS kann aus dem Systemcache beantwortet werden. Ein einzelner Testdienst kann selbst ausfallen. Die Messung beweist weder einen Fehler beim Anbieter noch die Erreichbarkeit aller Internetdienste.</p>
        <p class="muted">Keine Konten, keine hochgeladenen Messdaten. Die Prüfungen kontaktieren Cloudflare, Google und example.com. Dieser Bericht enthält die gewählte Gerätebezeichnung und technische Netzwerkdetails.</p>
        </body></html>
        """
    }

    public static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    public static func seconds(_ value: Double) -> String {
        String(format: "%.1f s", value)
    }
}
