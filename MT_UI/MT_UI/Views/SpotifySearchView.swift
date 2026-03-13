// Search sheet/modal for querying Spotify.
// Displayed as a .sheet() from MetadataEditorView.
// Displays a list of matching tracks; selecting one populates the metadata editor.

import SwiftUI

struct SpotifySearchView: View {
    @Binding var file: MusicFile?
    @Environment(\.dismiss) var dismiss
    @State private var query: String = ""
    @State private var results: [Track] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack {
            // MARK: - Search Bar
            // Pre-filled with file title + artist on appear.
            HStack {
                TextField("Search", text: $query)
                Button("Search") {
                    Task {
                        do {
                            isLoading = true
                            results = try await APIClient.shared.searchTracks(query: query)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isLoading = false
                    }
                }
            }

            // MARK: - Results List
            // TODO: Show ProgressView when isLoading is true.
            // TODO: Show errorMessage if non-nil.
            // TODO: Show "No results for..." if results is empty and query is non-empty.
            // TODO: List(results) — each row: AsyncImage thumbnail, title (bold), artist — album, date.
            // TODO: On row tap — map track fields to file, call writeArtwork, dismiss.
        }
        .onAppear {
            query = (file?.title ?? "") + " " + (file?.artist ?? "")
        }
    }
}
