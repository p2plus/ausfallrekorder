import Foundation

public enum Health: String, Codable, Sendable {
    case online, local, internet, nameOrHTTPS, unknown

    public var title: String { title(in: .current) }

    public func title(in language: Language) -> String {
        let source: String = switch self {
        case .online: "Verbindung erreichbar"
        case .local: "Router und Internet antworten nicht"
        case .internet: "Router antwortet, Internetprüfung fehlgeschlagen"
        case .nameOrHTTPS: "IP erreichbar, DNS-/HTTPS-Prüfung fehlgeschlagen"
        case .unknown: "Verbindung nicht bestätigt"
        }
        return L.text(source, language: language)
    }
}

public struct Sample: Codable, Sendable {
    public var at: Date
    public var duration: Double
    public var gateway: Bool?
    public var external: Bool
    public var dns: Bool
    public var https: Bool
    public var network: String
    public var details: [String: String] = [:]
    public var health: Health {
        if https { return .online }
        if external { return .nameOrHTTPS }
        if gateway == true { return .internet }
        if gateway == false { return .local }
        return .unknown
    }

    public init(at: Date, duration: Double = 1, gateway: Bool? = true,
                external: Bool = true, dns: Bool = true, https: Bool = true,
                network: String = "test") {
        self.at = at; self.duration = duration; self.gateway = gateway
        self.external = external; self.dns = dns; self.https = https; self.network = network
    }
}

public struct Recording: Codable, Sendable {
    public var version = 1
    public var id = UUID()
    public var label: String
    public var started: Date
    public var ended: Date?
    public var interval: Double
    public var samples: [Sample] = []
    public init(label: String, started: Date = Date(), interval: Double = 15) {
        self.label = label; self.started = started; self.interval = interval
    }
}

public struct Incident: Sendable {
    public let start: Date
    public let end: Date
    public let health: Health
}

public enum Analysis {
    public static func incidents(_ recording: Recording) -> [Incident] {
        var result: [Incident] = []
        var previous: Sample?
        for sample in recording.samples {
            defer { previous = sample }
            guard sample.health != .online else { continue }
            let end = sample.at.addingTimeInterval(sample.duration)
            if let p = previous, let last = result.last,
               p.health == sample.health, p.network == sample.network,
               sample.at.timeIntervalSince(p.at) <= max(recording.interval * 2, p.duration + 1) {
                result[result.count - 1] = Incident(start: last.start, end: max(last.end, end), health: sample.health)
            } else {
                result.append(Incident(start: sample.at, end: end, health: sample.health))
            }
        }
        return result
    }

    public static func observedSeconds(_ recording: Recording) -> Double {
        windows(recording).reduce(0) { $0 + $1.duration }
    }

    public static func failedSeconds(_ recording: Recording) -> Double {
        windows(recording, failedOnly: true).reduce(0) { $0 + $1.duration }
    }

    public static func simultaneousSeconds(_ a: Recording, _ b: Recording) -> Double {
        overlap(windows(a, failedOnly: true), windows(b, failedOnly: true))
    }

    public static func sharedObservationSeconds(_ a: Recording, _ b: Recording) -> Double {
        overlap(windows(a), windows(b))
    }

    private static func windows(_ r: Recording, failedOnly: Bool = false) -> [DateInterval] {
        var result: [DateInterval] = []
        for s in r.samples where !failedOnly || s.health != .online {
            let end = s.at.addingTimeInterval(max(0, s.duration))
            if let last = result.last, s.at <= last.end {
                result[result.count - 1] = DateInterval(start: last.start, end: max(last.end, end))
            } else {
                result.append(DateInterval(start: s.at, end: end))
            }
        }
        return result
    }

    private static func overlap(_ a: [DateInterval], _ b: [DateInterval]) -> Double {
        var i = 0, j = 0
        var seconds = 0.0
        while i < a.count && j < b.count {
            seconds += max(0, min(a[i].end, b[j].end).timeIntervalSince(max(a[i].start, b[j].start)))
            if a[i].end < b[j].end { i += 1 } else { j += 1 }
        }
        return seconds
    }
}
