#if os(macOS)
import SwiftUI
import AppKit
import RecorderCore

struct RecorderPopover: View {
    @ObservedObject var model: RecorderModel
    @State private var showHistory = false
    private var last: Sample? { model.recording?.samples.last }
    private var samples: [Sample] { model.recording?.samples ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ausfallrekorder").font(.headline)
                Spacer()
                Text(model.running ? tr("MISST") : tr("PAUSIERT"))
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Circle().fill(last == nil ? .gray : last?.health == .online ? .green : .orange)
                        .frame(width: 8, height: 8)
                    Text(last?.health.title ?? (model.running ? tr("Erste Prüfung läuft …") : tr("Bereit, wenn du es bist.")))
                        .font(.system(size: 17, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
                }
                if let last {
                    Text(tr("Zuletzt %@ · %@", last.at.formatted(date: .omitted, time: .standard), model.recording?.label ?? ""))
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(tr("Router, Internet, DNS und HTTPS.")).font(.caption).foregroundStyle(.secondary)
                }
            }
            if let last {
                HStack(spacing: 0) {
                    probe(tr("Router"), last.gateway)
                    probe(tr("Internet"), last.external || last.https)
                    probe("DNS", last.dns)
                    probe("HTTPS", last.https)
                }
                Divider()
            }
            HStack {
                if model.running {
                    Button(model.stopping ? tr("Wird beendet …") : tr("Messung stoppen"), action: model.stop)
                        .disabled(model.stopping)
                } else {
                    Button(tr("Messung starten"), action: model.start).buttonStyle(.borderedProminent)
                }
                Spacer()
                if let recording = model.recording {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tr("%d Prüfungen", samples.count)).font(.callout.monospacedDigit())
                        Text(tr("%d Auffälligkeiten", Analysis.incidents(recording).count)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if model.running {
                Text(tr("Alle 15 Sekunden · endet nach 8 Stunden"))
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                TextField(tr("Gerätebezeichnung"), text: $model.label).textFieldStyle(.roundedBorder)
            }
            if !samples.isEmpty {
                DisclosureGroup(tr("Letzte Prüfungen"), isExpanded: $showHistory) {
                    VStack(spacing: 7) {
                        ForEach(Array(samples.suffix(5).reversed().enumerated()), id: \.offset) { _, sample in
                            HStack {
                                Text(sample.at.formatted(date: .omitted, time: .standard)).monospacedDigit()
                                Spacer()
                                Text(sample.health == .online ? tr("Erreichbar") : tr("Auffällig"))
                                    .foregroundStyle(sample.health == .online ? .secondary : .primary)
                                Image(systemName: sample.health == .online ? "checkmark" : "exclamationmark")
                            }.font(.caption)
                        }
                    }.padding(.top, 8)
                }.font(.callout)
            }
            if let comparison = model.comparison {
                Text(tr("Vergleich geladen: %@", comparison.label)).font(.caption).lineLimit(2)
            }
            if let error = model.error {
                Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled)
            }
            Divider()
            HStack {
                Menu(tr("Exportieren")) {
                    Button(tr("Bericht als HTML …")) { model.export(report: true) }
                    Button(tr("Messdatei exportieren …")) { model.export(report: false) }.disabled(model.recording == nil)
                }.disabled(model.recording == nil).fixedSize()
                Menu(tr("Öffnen")) {
                    Button(tr("Messung öffnen …")) { model.load() }.disabled(model.running)
                    Button(tr("Mit Messung vergleichen …")) { model.load(comparing: true) }
                        .disabled(model.recording == nil || model.running)
                }.fixedSize()
                Spacer()
                Button(tr("Beenden")) { NSApplication.shared.terminate(nil) }.keyboardShortcut("q")
            }
        }
        .padding(20).frame(width: 350)
    }

    private func probe(_ name: String, _ passed: Bool?) -> some View {
        VStack(spacing: 5) {
            Image(systemName: passed == nil ? "minus.circle" : passed == true ? "checkmark.circle.fill" : "questionmark.circle")
                .foregroundStyle(passed == true ? .green : .secondary)
            Text(name).font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }
}
#endif
