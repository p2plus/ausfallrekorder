import Foundation

public enum RecorderError: LocalizedError {
    case invalid(String)
    public var errorDescription: String? {
        switch self { case .invalid(let message): message }
    }
}

private struct Row: Codable {
    var sample: Sample?
    var ended: Date?
}

public enum Store {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }

    public static func create(_ recording: Recording, at url: URL) throws {
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw RecorderError.invalid("Die Datei existiert bereits. Bitte einen neuen Namen wählen.")
        }
        var data = try encoder().encode(recording)
        data.append(10)
        try data.write(to: url, options: [.withoutOverwriting])
    }

    public static func append(_ sample: Sample, to url: URL) throws {
        try appendRow(Row(sample: sample), to: url)
    }

    public static func finish(at date: Date, url: URL) throws {
        try appendRow(Row(ended: date), to: url)
    }

    private static func appendRow(_ row: Row, to url: URL) throws {
        let file = try FileHandle(forWritingTo: url)
        defer { try? file.close() }
        try file.seekToEnd()
        var data = try encoder().encode(row)
        data.append(10)
        try file.write(contentsOf: data)
        try file.synchronize()
    }

    public static func load(_ url: URL) throws -> Recording {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard (attributes[.size] as? NSNumber)?.intValue ?? Int.max <= 64 * 1024 * 1024 else {
            throw RecorderError.invalid("Die Messdatei ist größer als 64 MB.")
        }
        let data = try Data(contentsOf: url)
        // Only newline-terminated rows are committed. A torn last write is ignored.
        let lines = data.split(separator: 10, omittingEmptySubsequences: false)
        guard lines.count > 1 else { throw RecorderError.invalid("Keine vollständige Messdatei.") }
        var recording = try decoder().decode(Recording.self, from: Data(lines[0]))
        guard recording.version == 1, recording.interval.isFinite,
              (1...60).contains(recording.interval), recording.samples.isEmpty else {
            throw RecorderError.invalid("Unbekanntes oder ungültiges Messformat.")
        }
        var last = recording.started
        for line in lines.dropFirst().dropLast() {
            let row = try decoder().decode(Row.self, from: Data(line))
            guard recording.ended == nil else { throw RecorderError.invalid("Daten nach Messende.") }
            if let sample = row.sample {
                guard row.ended == nil, sample.at >= last,
                      sample.duration.isFinite, (0...30).contains(sample.duration),
                      sample.network.count <= 1024, recording.samples.count < 250_000 else {
                    throw RecorderError.invalid("Ungültige oder falsch sortierte Messwerte.")
                }
                recording.samples.append(sample)
                last = sample.at
            } else if let ended = row.ended, ended >= last {
                recording.ended = ended
            } else {
                throw RecorderError.invalid("Ungültiger Eintrag in der Messdatei.")
            }
        }
        return recording
    }
}
