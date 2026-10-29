import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum Probes {
    // Reuse TLS connections. No cookies, cache, background service, or retries.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 3
        configuration.timeoutIntervalForResource = 3
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpMaximumConnectionsPerHost = 1
        return URLSession(configuration: configuration)
    }()
    public static func sample() async -> Sample {
        let start = Date()
        let clock = ContinuousClock.now
        let route = await defaultRoute()
        async let gateway = ping(route.address)
        async let cloudflare = ping("1.1.1.1")
        async let google = ping("8.8.8.8")
        async let dns = resolve()
        async let https = httpsProbe()
        let (g, c, p, d, h) = await (gateway, cloudflare, google, dns, https)
        let elapsed = clock.duration(to: .now)
        let duration = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        var result = Sample(at: start, duration: min(duration, 30), gateway: route.address == nil ? nil : g.success,
                            external: c.success || p.success, dns: d.success, https: h,
                            network: "\(route.interface) / \(route.address ?? "kein IPv4-Router")")
        result.details = [
            "Router": route.address == nil ? "Kein IPv4-Standardrouter gefunden" : (g.success ? "antwortet" : g.reason),
            "Routeradresse": route.address ?? "unbekannt",
            "Interface": route.interface,
            "Cloudflare IP": c.success ? "antwortet" : c.reason,
            "Google IP": p.success ? "antwortet" : p.reason,
            "DNS example.com": d.success ? "aufgelöst (Systemcache möglich)" : d.reason,
            "HTTPS": h ? "example.com erreichbar" : "example.com nicht bestätigt"
        ]
        return result
    }

    static func executable(_ paths: [String]) -> String {
        paths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) ?? paths[0]
    }

    static func ping(_ address: String?) async -> CommandResult {
        guard let address else { return CommandResult(success: false, output: "", reason: "Kein Ziel") }
        #if os(macOS)
        let args = ["-n", "-c", "1", "-W", "1500", address]
        #else
        let args = ["-n", "-c", "1", "-W", "2", address]
        #endif
        return await Command.run(executable(["/sbin/ping", "/bin/ping", "/usr/bin/ping"]), args, timeout: 2.5)
    }

    static func resolve() async -> CommandResult {
        #if os(macOS)
        let result = await Command.run("/usr/bin/dscacheutil", ["-q", "host", "-a", "name", "example.com"])
        #else
        let result = await Command.run("/usr/bin/getent", ["ahosts", "example.com"])
        #endif
        return CommandResult(success: result.success && !result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                             output: "", reason: result.reason)
    }

    static func defaultRoute() async -> (address: String?, interface: String) {
        #if os(macOS)
        let result = await Command.run("/sbin/route", ["-n", "get", "default"])
        let lines = result.output.split(separator: "\n")
        func value(_ name: String) -> String? {
            lines.first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix(name + ":") })?
                .split(separator: ":", maxSplits: 1).last?.trimmingCharacters(in: .whitespaces)
        }
        let address = value("gateway")
        return (address.flatMap { validIPv4($0) ? $0 : nil }, value("interface") ?? "unbekannt")
        #else
        let result = await Command.run(executable(["/usr/sbin/ip", "/sbin/ip", "/usr/bin/ip", "/bin/ip"]), ["-4", "route", "get", "1.1.1.1"])
        let words = result.output.split(whereSeparator: \.isWhitespace).map(String.init)
        func following(_ word: String) -> String? {
            guard let i = words.firstIndex(of: word), i + 1 < words.count else { return nil }
            return words[i + 1]
        }
        return (following("via").flatMap { validIPv4($0) ? $0 : nil }, following("dev") ?? "unbekannt")
        #endif
    }

    static func validIPv4(_ text: String) -> Bool {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 4 && parts.allSatisfy { part in
            !part.isEmpty && part.allSatisfy(\.isNumber) && UInt8(part) != nil
        }
    }

    static func httpsProbe() async -> Bool {
        var request = URLRequest(url: URL(string: "https://example.com/")!, timeoutInterval: 3)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse).map { (200...299).contains($0.statusCode) } ?? false
        } catch { return false }
    }
}
