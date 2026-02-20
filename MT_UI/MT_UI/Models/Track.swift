// Represents a Spotify track search result.
// Maps to the JSON response from the backend /search endpoint.
// Must mirror SpotifyTrack from the backend (Backend/models.py).

import Foundation

// TODO: Conform to Identifiable using spotifyId as the id.
// TODO: Conform to Decodable so URLSession/JSONDecoder can deserialise the backend response.

struct Track {

    // TODO: spotifyId — String. Maps to "spotify_id" in JSON.
    //       Use CodingKeys to map snake_case JSON keys to camelCase Swift properties.

    // TODO: title — String. Maps to "title" in JSON.

    // TODO: artist — String. Maps to "artist" in JSON.

    // TODO: album — String. Maps to "album" in JSON.

    // TODO: date — String. Maps to "date" in JSON.

    // TODO: artworkUrl — String. Maps to "artwork_url" in JSON.
    //       Used to fetch and display album art in the search results list.
    //       Also passed to /write-artwork as artwork_path when the user confirms a result.
}
