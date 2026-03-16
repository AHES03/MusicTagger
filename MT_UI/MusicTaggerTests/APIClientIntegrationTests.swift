// XCTest integration suite for APIClient.
// Requires the backend to be running on http://127.0.0.1:8000.
// Requires a real audio file path — update TEST_FILE_PATH before running.
// Run via Product > Test in Xcode (requires MT_UITests target).

import XCTest
@testable import MT_UI

// MARK: - Configure before running
private let TEST_FILE_PATH = ("~/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac" as NSString).expandingTildeInPath
final class APIClientIntegrationTests: XCTestCase {

    // MARK: - /health

    func testHealthCheck() async throws {
        let isOnline = try await APIClient.shared.healthCheck()
        XCTAssertTrue(isOnline, "Backend should respond with 200 on /health")
    }

    // MARK: - /search

    func testSearchTracksReturnsResults() async throws {
        let tracks = try await APIClient.shared.searchTracks(query: "Bohemian Rhapsody Queen")
        XCTAssertFalse(tracks.isEmpty, "Search should return at least one result")
    }

    func testSearchTracksResultShape() async throws {
        let tracks = try await APIClient.shared.searchTracks(query: "Bohemian Rhapsody Queen")
        guard let first = tracks.first else {
            XCTFail("Expected at least one result")
            return
        }
        XCTAssertFalse(first.spotifyId.isEmpty)
        XCTAssertFalse(first.title.isEmpty)
        XCTAssertFalse(first.artist.isEmpty)
        XCTAssertFalse(first.album.isEmpty)
        XCTAssertFalse(first.artworkUrl.isEmpty)
    }

    func testSearchTracksEmptyQueryThrows() async {
        do {
            _ = try await APIClient.shared.searchTracks(query: "")
            XCTFail("Expected an error for empty query")
        } catch {
            // Expected — backend returns 422 for empty query
        }
    }

    // MARK: - /read-metadata

    func testReadMetadataReturnsFile() async throws {
        guard TEST_FILE_PATH != "/path/to/your/test.flac" else {
            throw XCTSkip("Set TEST_FILE_PATH to a real audio file before running this test")
        }
        let file = try await APIClient.shared.readMetadata(filePath: TEST_FILE_PATH)
        XCTAssertEqual(file.filePath, TEST_FILE_PATH)
    }

    func testReadMetadataMissingFileThrows() async {
        do {
            _ = try await APIClient.shared.readMetadata(filePath: "/nonexistent/file.flac")
            XCTFail("Expected an error for missing file")
        } catch {
            // Expected — backend returns 404
        }
    }
}
