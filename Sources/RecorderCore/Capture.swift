import Foundation

public enum Capture {
    /// One loop owns the file. Callers cancel the task to stop and flush it.
    public static func run(_ initial: Recording, at url: URL, seconds: Double = 28_800,
                           onSample: @escaping @Sendable (Sample) async -> Void = { _ in }) async throws -> Recording {
        guard (1...60).contains(initial.interval), (1...86_400).contains(seconds) else {
            throw RecorderError.invalid("Intervall: 1–60 Sekunden. Messdauer: 1–86400 Sekunden.")
        }
        try Store.create(initial, at: url)
        var recording = initial
        let deadline = ContinuousClock.now.advanced(by: .seconds(seconds))
        while !Task.isCancelled && ContinuousClock.now < deadline {
            let tick = ContinuousClock.now
            let sample = await Probes.sample()
            if Task.isCancelled { break }
            // A machine that slept during a probe did not observe a long outage.
            if sample.duration < 15 && sample.at >= (recording.samples.last?.at ?? initial.started) {
                try Store.append(sample, to: url)
                recording.samples.append(sample)
                await onSample(sample)
            }
            let next = min(tick.advanced(by: .seconds(initial.interval)), deadline)
            if next > ContinuousClock.now {
                do { try await Task.sleep(until: next, clock: .continuous) }
                catch { break }
            }
        }
        recording.ended = Date()
        try Store.finish(at: recording.ended!, url: url)
        return recording
    }
}
