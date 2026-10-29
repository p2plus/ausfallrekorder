import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

public struct CommandResult: Sendable {
    public let success: Bool
    public let output: String
    public let reason: String
}

public enum Command {
    public static func run(_ executable: String, _ arguments: [String], timeout: Double = 2) async -> CommandResult {
        let pending = PendingCommand(executable, arguments, timeout: timeout)
        return await withTaskCancellationHandler {
            await withCheckedContinuation { pending.start($0) }
        } onCancel: { pending.stop("Abgebrochen") }
    }
}

/// Process completion and a single deadline, rather than a polling timer.
private final class PendingCommand: @unchecked Sendable {
    private let lock = NSLock()
    private let process = Process()
    private let pipe = Pipe()
    private let executable: String
    private let timeout: Double
    private var continuation: CheckedContinuation<CommandResult, Never>?
    private var stopped: String?
    private var deadline: DispatchWorkItem?

    init(_ executable: String, _ arguments: [String], timeout: Double) {
        self.executable = executable; self.timeout = timeout
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        process.environment = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "LC_ALL": "C"]
    }

    func start(_ continuation: CheckedContinuation<CommandResult, Never>) {
        lock.lock()
        if let stopped {
            lock.unlock()
            continuation.resume(returning: CommandResult(success: false, output: "", reason: stopped))
            return
        }
        guard FileManager.default.isExecutableFile(atPath: executable) else {
            lock.unlock()
            continuation.resume(returning: CommandResult(success: false, output: "", reason: "Programm fehlt: \(executable)"))
            return
        }
        self.continuation = continuation
        process.terminationHandler = { [self] _ in finish() }
        do {
            try process.run()
            let deadline = DispatchWorkItem { [weak self] in self?.stop("Zeitlimit") }
            self.deadline = deadline
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout, execute: deadline)
            lock.unlock()
        } catch {
            self.continuation = nil
            process.terminationHandler = nil
            lock.unlock()
            continuation.resume(returning: CommandResult(success: false, output: "", reason: error.localizedDescription))
        }
    }

    func stop(_ reason: String) {
        lock.lock()
        stopped = stopped ?? reason
        if process.isRunning {
            process.terminate()
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self else { return }
                self.lock.lock(); defer { self.lock.unlock() }
                if self.process.isRunning { _ = kill(self.process.processIdentifier, SIGKILL) }
            }
        }
        lock.unlock()
    }

    private func finish() {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        deadline?.cancel(); deadline = nil
        let reason = stopped
        process.terminationHandler = nil
        lock.unlock()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile().prefix(16_384), as: UTF8.self)
        try? pipe.fileHandleForReading.close()
        continuation?.resume(returning: CommandResult(success: reason == nil && process.terminationStatus == 0,
                                                     output: output, reason: reason ?? "Exit \(process.terminationStatus)"))
    }
}
