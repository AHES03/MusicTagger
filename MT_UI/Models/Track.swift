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
        case albumArtist = "album_artist"
        case title, artist, album, date
    }

    let spotifyId: String
    let title: String
    let artist: String
    let album: String
    let date: String
    let trackNumber: Int
    let albumArtist: String
    let artworkUrl: String // Passed to /write-artwork as artwork_path when user confirms a result.
    var id: String {
        spotifyId
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spotifyId = try container.decode(String.self, forKey: .spotifyId)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        album = try container.decode(String.self, forKey: .album)
        date = try container.decode(String.self, forKey: .date)
        albumArtist = try container.decode(String.self, forKey: .albumArtist)
        trackNumber = try container.decode(Int.self, forKey: .trackNumber)
        artworkUrl = try container.decode(String.self, forKey: .artworkUrl)
    }
}
