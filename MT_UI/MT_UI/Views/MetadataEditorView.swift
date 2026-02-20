// Shows editable fields for a selected file's metadata.
// Left panel in the two-panel layout. Matches the form in Example.png.
// Includes a "Search Spotify" button to auto-fill from API results.

import SwiftUI

// TODO: Create a MetadataEditorView struct conforming to View.
//       Receives a `Binding<MusicFile?>` from ContentView.
//       When selectedFile is nil, show a placeholder: "Select a file to edit its metadata."

// MARK: - Text Fields

// TODO: Row: "Title"       — full-width TextField bound to selectedFile?.title
// TODO: Row: "Artist"      — full-width TextField bound to selectedFile?.artist
// TODO: Row: "Album"       — full-width TextField bound to selectedFile?.album

// MARK: - Inline Row (Year / Track / Genre)

// TODO: Single HStack row containing three shorter fields:
//         "Year"   — narrow TextField bound to selectedFile?.date
//         "Track"  — narrow TextField bound to selectedFile?.trackNumber (Int? ↔ String conversion)
//         "Genre"  — TextField bound to selectedFile?.genre
//       Match the compact inline layout visible in Example.png.

// MARK: - More Text Fields

// TODO: Row: "Comment"      — full-width TextField (not in current MusicFile model — add if needed)
// TODO: Row: "Album Artist" — full-width TextField (not in current MusicFile model — add if needed)
// TODO: Row: "Composer"     — full-width TextField (not in current MusicFile model — add if needed)

// MARK: - Disc / Compilation Row

// TODO: Single HStack row:
//         "Disc Number"  — narrow TextField (not in current MusicFile model — add if needed)
//         "Compilation"  — Toggle/Checkbox (Bool field, not in current model — add if needed)
//       Note: if these fields are added to MusicFile, update MetadataPayload in the backend too.

// MARK: - Album Artwork

// TODO: Artwork preview area at the bottom of the left panel (matches Example.png disc icon area).
//       If selectedFile?.artworkData is non-nil, display the image using Image(nsImage:).
//       Otherwise show a placeholder (SF Symbol: "opticaldisc" or similar).
//       Tapping/clicking the artwork should open a file picker to choose a new image,
//       then call APIClient.writeArtwork(filePath:artworkPath:).
//       Dragging an image file onto the artwork area should also trigger write-artwork.

// MARK: - Actions

// TODO: "Search Spotify" button.
//       Opens SpotifySearchView as a sheet: .sheet(isPresented: $showingSpotifySearch) { ... }
//       On selection, auto-fill text fields from the returned Track object.
//       Also call APIClient.writeArtwork using the track's artworkUrl.

// TODO: "Save" / "Write Tags" button (or handle via toolbar in ContentView).
//       Calls APIClient.writeMetadata(file: selectedFile).
//       Show success/failure feedback (e.g. a brief status label or alert).

// MARK: - Layout Notes

// TODO: Wrap all rows in a ScrollView in case content overflows the panel height.
// TODO: Use Form{} or a VStack with consistent spacing/padding to match Example.png style.
// TODO: Labels should be right-aligned, fields left-aligned — or use LabeledContent{} rows.
// TODO: Fixed width ~200pt for the whole panel; fields should fill available width.
