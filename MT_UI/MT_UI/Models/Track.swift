// Represents a Spotify track search result.
// Maps to the JSON response from the backend /search endpoint.
// Must mirror SpotifyTrack from the backend (Backend/models.py).

import Foundation

// Conforms to Identifiable (id = spotifyId) and Decodable (JSON → struct).
// CodingKeys maps snake_case JSON keys to camelCase Swift properties.
// All fields are non-optional — the backend always returns values for Spotify tracks.

struct Track: Identifiable, Decodable {

    enum CodingKeys: String, CodingKey {
        case spotifyId = "spotify_id"
        case artworkUrl = "artwork_url"
        case trackNumber = "track_number"
        case title, artist, album, date
    }

    let spotifyId: String
    let title: String
    let artist: String
    let album: String
    let date: String
    let trackNumber: Int
    let artworkUrl: String  // Passed to /write-artwork as artwork_path when user confirms a result.
    var id: String{spotifyId}
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.spotifyId = try container.decode(String.self, forKey: .spotifyId)
        self.title = try container.decode(String.self, forKey: .title)
        self.artist = try container.decode(String.self, forKey: .artist)
        self.album = try container.decode(String.self, forKey: .album)
        self.date = try container.decode(String.self, forKey: .date)
        self.trackNumber = try container.decode(Int.self, forKey: .trackNumber)
        self.artworkUrl = try container.decode(String.self, forKey: .artworkUrl)
    }
}
