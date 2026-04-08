// Represents a search result track from either Spotify or iTunes.
// Maps to the JSON response from the backend /search and /search-itunes endpoints.
// Must mirror SpotifyTrack and iTunesTrack from the backend (Backend/models.py).

import Foundation

// Conforms to Identifiable (id = sourceId) and Decodable (JSON → struct).
// CodingKeys maps snake_case JSON keys to camelCase Swift properties.
// sourceId decodes from either spotify_id or itunes_id depending on the source.
// All other fields are non-optional — the backend always returns values for both sources.

struct Track: Identifiable, Decodable {
    enum CodingKeys: String, CodingKey {
        case spotifyId = "spotify_id"
        case itunesId = "itunes_id"
        case artworkUrl = "artwork_url"
        case trackNumber = "track_number"
        case albumArtist = "album_artist"
        case title, artist, album, date, genre
    }

    let sourceId: String // spotify_id for Spotify results, itunes_id for iTunes results.
    let title: String
    let artist: String
    let album: String
    let date: String
    let trackNumber: Int
    let albumArtist: String
    let artworkUrl: String // Passed to /write-artwork as artwork_path when user confirms a result.
    let genre: String?
    var id: String { sourceId }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let spotifyId = try container.decodeIfPresent(String.self, forKey: .spotifyId)
        let itunesId = try container.decodeIfPresent(String.self, forKey: .itunesId)
        sourceId = spotifyId ?? itunesId ?? ""
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        album = try container.decode(String.self, forKey: .album)
        date = try container.decode(String.self, forKey: .date)
        albumArtist = try container.decode(String.self, forKey: .albumArtist)
        trackNumber = try container.decode(Int.self, forKey: .trackNumber)
        artworkUrl = try container.decode(String.self, forKey: .artworkUrl)
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
    }
}
