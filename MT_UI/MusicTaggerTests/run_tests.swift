// Standalone Swift test script for APIClient endpoints.
// Does NOT require Xcode — run from terminal:
//   swift run_tests.swift /path/to/your/test.flac
//
// Requires backend running on http://127.0.0.1:8000.
// Pass a real audio file path as the first argument for read-metadata tests.

import Foundation

// MARK: - Helpers

let BASE_URL = "http://127.0.0.1:8000"
var passed = 0
var failed = 0

func pass(_ name: String) {
    print("  ✅ \(name)")
    passed += 1
}

func fail(_ name: String, _ reason: String) {
    print("  ❌ \(name): \(reason)")
    failed += 1
}

func post(path: String, body: [String: String]) async throws -> Data {
    var request = URLRequest(url: URL(string: BASE_URL + path)!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(body)
    let (data, _) = try await URLSession.shared.data(for: request)
    return data
}

func get(path: String) async throws -> (Data, Int) {
    let (data, response) = try await URLSession.shared.data(from: URL(string: BASE_URL + path)!)
    let status = (response as! HTTPURLResponse).statusCode
    return (data, status)
}

// MARK: - Tests

func runTests(testFilePath: String?) async {

    // ── /health ──────────────────────────────────────────────
    print("\n/health")
    do {
        let (_, status) = try await get(path: "/health")
        if status == 200 { pass("returns 200") } else { fail("returns 200", "got \(status)") }
    } catch { fail("returns 200", error.localizedDescription) }

    // ── /search ───────────────────────────────────────────────
    print("\n/search")
    do {
        let data = try await post(path: "/search", body: ["query": "Bohemian Rhapsody Queen"])
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        if let tracks = json["Tracks"] as? [[String: Any]] {
            if !tracks.isEmpty { pass("returns results") } else { fail("returns results", "empty array") }
            let first = tracks[0]
            if first["spotify_id"] is String { pass("track has spotify_id") } else { fail("track has spotify_id", "missing") }
            if first["title"] is String      { pass("track has title")     } else { fail("track has title", "missing") }
            if first["artwork_url"] is String { pass("track has artwork_url") } else { fail("track has artwork_url", "missing") }
        } else { fail("returns results", "no 'Tracks' key in response") }
    } catch { fail("/search request", error.localizedDescription) }

    do {
        let data = try await post(path: "/search", body: ["query": ""])
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        if json["detail"] != nil { pass("empty query returns error") } else { fail("empty query returns error", "no detail key") }
    } catch { fail("empty query returns error", error.localizedDescription) }

    // ── /read-metadata ────────────────────────────────────────
    print("\n/read-metadata")
    if let path = testFilePath {
        do {
            let data = try await post(path: "/read-metadata", body: ["file_path": path])
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            if let metadata = json["Metadata"] as? [String: Any] {
                if metadata["file_path"] as? String == path { pass("returns correct file_path") } else { fail("returns correct file_path", "mismatch") }
                pass("Metadata key present")
            } else { fail("Metadata key present", "missing in response") }
        } catch { fail("/read-metadata request", error.localizedDescription) }
    } else {
        print("  ⏭  /read-metadata skipped — pass a file path as argument: swift run_tests.swift /path/to/file.flac")
    }

    do {
        let data = try await post(path: "/read-metadata", body: ["file_path": "/nonexistent/file.flac"])
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        if json["detail"] != nil { pass("missing file returns error") } else { fail("missing file returns error", "no detail key") }
    } catch { fail("missing file returns error", error.localizedDescription) }

    // ── Summary ───────────────────────────────────────────────
    print("\n────────────────────────────")
    print("  \(passed) passed, \(failed) failed")
    print("────────────────────────────\n")
}

// MARK: - Entry point

let testFilePath = CommandLine.arguments.dropFirst().first

let sema = DispatchSemaphore(value: 0)
Task {
    await runTests(testFilePath: testFilePath)
    sema.signal()
}
sema.wait()
