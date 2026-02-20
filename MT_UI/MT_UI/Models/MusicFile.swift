// Represents a local music file with its current metadata.
// Holds the file path and all editable tag fields.
// Must mirror MetadataPayload from the backend (Backend/models.py).

import Foundation

// TODO: Conform to Identifiable so it can be used in SwiftUI List/Table views.
// TODO: Conform to Hashable if selection sets are needed.
// TODO: Consider making this an ObservableObject if per-file change tracking is needed,
//       or keep as a plain struct managed by a parent ViewModel.

struct MusicFile {

    // TODO: file_path — String. Full absolute path to the audio file on disk.
    //       This is the primary key sent with every backend request.

    // TODO: title — String? Optional. Maps to "title" tag.

    // TODO: artist — String? Optional. Maps to "artist" tag.

    // TODO: album — String? Optional. Maps to "album" tag.

    // TODO: trackNumber — Int? Optional. Maps to "track_number" tag.
    //       Note the snake_case ↔ camelCase conversion from backend JSON.

    // TODO: date — String? Optional. Maps to "date" tag (e.g. "2021" or "2021-06-01").
    //       Stored as String to match backend — validate/format on display if needed.

    // TODO: genre — String? Optional. Maps to "genre" tag.

    // TODO: spotifyId — String? Optional. Maps to "spotify_id" tag.
    //       Stored for potential future use; not required for metadata writing.

    // TODO: artworkData — Data? Optional. In-memory image bytes for the artwork preview.
    //       NOT sent to backend directly — artwork is written via /write-artwork endpoint
    //       using a file path or URL, not raw bytes from this model.
    //       Loaded separately after reading metadata.
}
