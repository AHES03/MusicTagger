// XCTest suite for MusicFile and Track model decoding.
// Tests that CodingKeys, custom init(from:), and optional fields
// behave correctly when given valid and partial JSON payloads.
// Run via Product > Test in Xcode (requires MT_UITests target).

import XCTest
@testable import MusicTagger

final class ModelDecodingTests: XCTestCase {

    // MARK: - MusicFile

    func testMusicFileDecodesFullPayload() throws {
        let json = """
        {
            "file_path": "/music/track.flac",
            "title": "So Much Has Changed",
            "artist": "MARO",
            "album": "So Much Has Changed",
            "track_number": 2,
            "date": "2021",
            "genre": "Pop",
            "comment": "great track",
            "album_artist": "MARO",
            "composer": "MARO",
            "disc_number": 1,
            "is_compilation": false,
            "spotify_id": "abc123"
        }
        """.data(using: .utf8)!

        let file = try JSONDecoder().decode(MusicFile.self, from: json)

        XCTAssertEqual(file.filePath, "/music/track.flac")
        XCTAssertEqual(file.title, "So Much Has Changed")
        XCTAssertEqual(file.artist, "MARO")
        XCTAssertEqual(file.album, "So Much Has Changed")
        XCTAssertEqual(file.trackNumber, 2)
        XCTAssertEqual(file.date, "2021")
        XCTAssertEqual(file.genre, "Pop")
        XCTAssertEqual(file.comment, "great track")
        XCTAssertEqual(file.albumArtist, "MARO")
        XCTAssertEqual(file.composer, "MARO")
        XCTAssertEqual(file.discNumber, 1)
        XCTAssertEqual(file.isCompilation, false)
        XCTAssertEqual(file.spotifyId, "abc123")
        XCTAssertNil(file.artworkData)   // UI-only — never decoded from JSON
        XCTAssertNil(file.artworkUrl)    // UI-only — never decoded from JSON
    }

    func testMusicFileDecodesPartialPayload() throws {
        // Only file_path is required — all other fields are optional.
        let json = """
        {
            "file_path": "/music/track.mp3"
        }
        """.data(using: .utf8)!

        let file = try JSONDecoder().decode(MusicFile.self, from: json)

        XCTAssertEqual(file.filePath, "/music/track.mp3")
        XCTAssertNil(file.title)
        XCTAssertNil(file.artist)
        XCTAssertNil(file.album)
        XCTAssertNil(file.trackNumber)
        XCTAssertNil(file.genre)
        XCTAssertNil(file.comment)
        XCTAssertNil(file.albumArtist)
        XCTAssertNil(file.composer)
        XCTAssertNil(file.discNumber)
        XCTAssertNil(file.isCompilation)
        XCTAssertNil(file.spotifyId)
    }

    func testMusicFileIDEqualsFilePath() throws {
        let json = """
        { "file_path": "/music/track.flac" }
        """.data(using: .utf8)!

        let file = try JSONDecoder().decode(MusicFile.self, from: json)
        XCTAssertEqual(file.id, file.filePath)
    }

    func testMusicFileEncodesSnakeCaseKeys() throws {
        let json = """
        {
            "file_path": "/music/track.flac",
            "track_number": 3,
            "album_artist": "Various",
            "disc_number": 2,
            "is_compilation": true,
            "spotify_id": "xyz"
        }
        """.data(using: .utf8)!

        let file = try JSONDecoder().decode(MusicFile.self, from: json)
        let encoded = try JSONEncoder().encode(file)
        let dict = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]

        XCTAssertEqual(dict["file_path"] as? String, "/music/track.flac")
        XCTAssertEqual(dict["track_number"] as? Int, 3)
        XCTAssertEqual(dict["album_artist"] as? String, "Various")
        XCTAssertEqual(dict["disc_number"] as? Int, 2)
        XCTAssertEqual(dict["is_compilation"] as? Bool, true)
        XCTAssertEqual(dict["spotify_id"] as? String, "xyz")
        // UI-only fields must not appear in encoded output
        XCTAssertNil(dict["artworkData"])
        XCTAssertNil(dict["artworkUrl"])
    }

    // MARK: - Track

    func testTrackDecodesFullPayload() throws {
        let json = """
        {
            "spotify_id": "abc123",
            "title": "So Much Has Changed",
            "artist": "MARO",
            "album": "So Much Has Changed",
            "date": "2021",
            "artwork_url": "https://example.com/art.jpg"
        }
        """.data(using: .utf8)!

        let track = try JSONDecoder().decode(Track.self, from: json)

        XCTAssertEqual(track.spotifyId, "abc123")
        XCTAssertEqual(track.title, "So Much Has Changed")
        XCTAssertEqual(track.artist, "MARO")
        XCTAssertEqual(track.album, "So Much Has Changed")
        XCTAssertEqual(track.date, "2021")
        XCTAssertEqual(track.artworkUrl, "https://example.com/art.jpg")
        XCTAssertEqual(track.id, "abc123")
    }

    func testSearchResponseDecodes() throws {
        let json = """
        {
            "Tracks": [
                {
                    "spotify_id": "abc123",
                    "title": "So Much Has Changed",
                    "artist": "MARO",
                    "album": "So Much Has Changed",
                    "date": "2021",
                    "artwork_url": "https://example.com/art.jpg"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(SearchResponse.self, from: json)

        XCTAssertEqual(response.tracks.count, 1)
        XCTAssertEqual(response.tracks[0].title, "So Much Has Changed")
    }

    func testReadMetadataResponseDecodes() throws {
        let json = """
        {
            "Metadata": {
                "file_path": "/music/track.flac",
                "title": "So Much Has Changed"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ReadMetadataResponse.self, from: json)
        XCTAssertEqual(response.file.filePath, "/music/track.flac")
        XCTAssertEqual(response.file.title, "So Much Has Changed")
    }
}
