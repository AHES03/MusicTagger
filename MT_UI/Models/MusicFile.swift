// Represents a local music file with its current metadata.
// Holds the file path and all editable tag fields.
// Must mirror MetadataPayload from the backend (Backend/models.py).

import Foundation

// Conforms to Identifiable (for SwiftUI Table/List), Hashable (for selection sets),
// and Codable (for JSON encoding/decoding with the backend).
// CodingKeys maps snake_case JSON keys to camelCase Swift properties.
// artworkData is decoded from the backend response (base64 string → Data) but excluded from write requests.

struct MusicFile: Identifiable, Hashable, Codable {
    enum CodingKeys: String, CodingKey {
        case filePath = "file_path",
             trackNumber = "track_number",
             albumArtist = "album_artist",
             discNumber = "disc_number",
             isCompilation = "is_compilation",
             artworkData = "artwork_data",
             sampleRate = "sample_rate",
             bitDepth = "bit_depth",
             title, artist, album, date, genre, comment, composer, format
    }

    let filePath: String // Primary key — sent with every backend request.
    var title: String?
    var artist: String?
    var album: String?
    var trackNumber: Int?
    var date: String? // Stored as String to match backend (e.g. "2021" or "2021-06-01").
    var genre: String?
    var comment: String?
    var albumArtist: String?
    var composer: String?
    var discNumber: Int?
    var isCompilation: Bool?
    var artworkData: Data? // Decoded from backend base64 response; not sent on writes.
    var artworkUrl: String? // UI-only — stored from Spotify selection for Save to use.
    var sampleRate: Int?
    var bitDepth: Int?
    var format: String?
    var id: String {
        filePath
    }

    /// Non-optional sort keys for TableColumn value: comparators.
    var sortTitle: String {
        title ?? ""
    }

    var sortArtist: String {
        artist ?? ""
    }

    var sortAlbum: String {
        album ?? ""
    }

    var sortTrackNumber: Int {
        trackNumber ?? 0
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filePath)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        filePath = try container.decode(String.self, forKey: .filePath)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        artist = try container.decodeIfPresent(String.self, forKey: .artist)
        album = try container.decodeIfPresent(String.self, forKey: .album)
        trackNumber = try container.decodeIfPresent(Int.self, forKey: .trackNumber)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        albumArtist = try container.decodeIfPresent(String.self, forKey: .albumArtist)
        composer = try container.decodeIfPresent(String.self, forKey: .composer)
        discNumber = try container.decodeIfPresent(Int.self, forKey: .discNumber)
        isCompilation = try container.decodeIfPresent(Bool.self, forKey: .isCompilation)
        artworkData = try container.decodeIfPresent(Data.self, forKey: .artworkData)
        sampleRate = try container.decodeIfPresent(Int.self, forKey: .sampleRate)
        bitDepth = try container.decodeIfPresent(Int.self, forKey: .bitDepth)
        format = try container.decodeIfPresent(String.self, forKey: .format)
    }
}
