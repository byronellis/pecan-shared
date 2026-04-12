import Testing
import Foundation
@testable import PecanShared

@Suite("ServerStatus")
struct ServerStatusTests {

    // MARK: - Codable round-trip

    @Test("encodes and decodes round-trip")
    func roundTrip() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let status = ServerStatus(pid: 12345, port: 3000, grpcSocketPath: "/tmp/grpc.sock", startedAt: now)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(status)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ServerStatus.self, from: data)

        #expect(decoded.pid == 12345)
        #expect(decoded.port == 3000)
        #expect(decoded.grpcSocketPath == "/tmp/grpc.sock")
        // Dates compared at second resolution (ISO 8601 truncates sub-second)
        #expect(abs(decoded.startedAt.timeIntervalSince(now)) < 1.0)
    }

    @Test("JSON contains expected keys")
    func jsonKeys() throws {
        let status = ServerStatus(pid: 1, port: 3000, grpcSocketPath: "/run/grpc.sock")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(status)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["pid"] != nil)
        #expect(json["port"] as? Int == 3000)
        #expect(json["grpcSocketPath"] as? String == "/run/grpc.sock")
        #expect(json["startedAt"] != nil)
    }

    // MARK: - File I/O

    @Test("write and read round-trip via temp file")
    func writeReadRoundTrip() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("server-status-test-\(UUID().uuidString)")
        let runDir = tmpDir.appendingPathComponent(".run")
        try FileManager.default.createDirectory(at: runDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        // Write to a temp file directly (bypassing CWD dependency)
        let status = ServerStatus(pid: 99, port: 50001, grpcSocketPath: "/tmp/test.sock")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(status)
        let filePath = runDir.appendingPathComponent("server.json")
        try data.write(to: filePath, options: .atomic)

        let readData = try Data(contentsOf: filePath)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ServerStatus.self, from: readData)

        #expect(decoded.pid == 99)
        #expect(decoded.port == 50001)
        #expect(decoded.grpcSocketPath == "/tmp/test.sock")
    }

    // MARK: - isAlive

    @Test("isAlive returns true for the current process")
    func isAliveCurrentProcess() {
        let pid = ProcessInfo.processInfo.processIdentifier
        let status = ServerStatus(pid: pid, port: 3000, grpcSocketPath: "/tmp/test.sock")
        #expect(status.isAlive)
    }

    @Test("isAlive returns false for invalid PID")
    func isAliveInvalidPID() {
        // PID 0 is the kernel on macOS; kill(0, 0) actually succeeds (signals the process group).
        // Use a large PID that is very unlikely to exist.
        let status = ServerStatus(pid: 2_000_000, port: 3000, grpcSocketPath: "/tmp/test.sock")
        #expect(!status.isAlive)
    }

    // MARK: - statusFilePath

    @Test("statusFilePath ends with .run/server.json")
    func statusFilePath() {
        #expect(ServerStatus.statusFilePath.hasSuffix("/.run/server.json"))
    }

    @Test("statusFilePath is relative to current directory")
    func statusFilePathMatchesCWD() {
        let cwd = FileManager.default.currentDirectoryPath
        #expect(ServerStatus.statusFilePath == "\(cwd)/.run/server.json")
    }
}
