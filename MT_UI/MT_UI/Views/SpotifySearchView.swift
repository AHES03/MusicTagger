// Search sheet/modal for querying Spotify.
// Displayed as a .sheet() from MetadataEditorView.
// Displays a list of matching tracks; selecting one populates the metadata editor.

import SwiftUI

// TODO: Create a SpotifySearchView struct conforming to View.
//       Receives:
//         - a binding or callback to pass the selected Track back to MetadataEditorView
//         - dismiss environment value to close the sheet on selection

// MARK: - Search Bar

// TODO: A TextField at the top for the search query.
//       Bound to a local @State var query: String.
//       Trigger APIClient.searchTracks(query:) on:
//         - pressing Return/Enter
//         - or a "Search" button next to the field

// MARK: - Results List

// TODO: Display results as a List of Track items.
//       Each row should show:
//         - Artwork thumbnail (loaded asynchronously from track.artworkUrl using AsyncImage)
//         - Title (bold)
//         - Artist — Album (secondary text)
//         - Date (year, trailing)

// TODO: Show a loading indicator (ProgressView) while the search request is in flight.
//       Use a @State var isLoading: Bool toggled around the async call.

// TODO: Show an empty state if results is empty and a search has been made:
//         "No results found for \"\(query)\"."

// TODO: Show an error message if the backend call fails.

// MARK: - Selection

// TODO: On row tap, call the callback/binding with the selected Track and dismiss the sheet.
//       The caller (MetadataEditorView) maps Track fields → MusicFile fields:
//         track.title      → file.title
//         track.artist     → file.artist
//         track.album      → file.album
//         track.date       → file.date
//         track.spotifyId  → file.spotifyId
//       And calls APIClient.writeArtwork(filePath: file.filePath, artworkPath: track.artworkUrl).
