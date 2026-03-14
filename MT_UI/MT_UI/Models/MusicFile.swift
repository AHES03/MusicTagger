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
             spotifyId = "spotify_id",
             albumArtist = "album_artist",
             discNumber = "disc_number",
             isCompilation = "is_compilation",
             artworkData = "artwork_data",
             title, artist, album, date, genre, comment, composer
    }

    let filePath : String   // Primary key — sent with every backend request.
    var title : String?
    var artist : String?
    var album : String?
    var trackNumber : Int?
    var date : String?      // Stored as String to match backend (e.g. "2021" or "2021-06-01").
    var genre : String?
    var comment : String?
    var albumArtist : String?
    var composer : String?
    var discNumber : Int?
    var isCompilation : Bool?
    var spotifyId : String?
    var artworkData : Data? = nil   // Decoded from backend base64 response; not sent on writes.
    var artworkUrl : String? = nil  // UI-only — stored from Spotify selection for Save to use.
    var id: String {filePath}
    func hash(into hasher: inout Hasher) {
        hasher.combine(filePath)
    }
    init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.filePath = try container.decode(String.self, forKey: .filePath)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.artist = try container.decodeIfPresent(String.self, forKey: .artist)
        self.album = try container.decodeIfPresent(String.self, forKey: .album)
        self.trackNumber = try container.decodeIfPresent(Int.self, forKey: .trackNumber)
        self.date = try container.decodeIfPresent(String.self, forKey: .date)
        self.genre = try container.decodeIfPresent(String.self, forKey: .genre)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.albumArtist = try container.decodeIfPresent(String.self, forKey: .albumArtist)
        self.composer = try container.decodeIfPresent(String.self, forKey: .composer)
        self.discNumber = try container.decodeIfPresent(Int.self, forKey: .discNumber)
        self.isCompilation = try container.decodeIfPresent(Bool.self, forKey: .isCompilation)
        self.spotifyId = try container.decodeIfPresent(String.self, forKey: .spotifyId)
        self.artworkData = try container.decodeIfPresent(Data.self, forKey: .artworkData)
    }
    
}
