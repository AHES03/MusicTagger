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

            if isLoading{
                ProgressView()
            }
            if let error = errorMessage {
                Text(error)
            }
            if results.isEmpty && !query.isEmpty && !isLoading {
                Text("No results for \"\(query)\"")
            }
            List(results) {track in
                HStack {
                    AsyncImage(url: URL(string: track.artworkUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable().frame(width: 50, height: 50)
                        case .failure:
                            Image(systemName: "music.note")
                            
                        @unknown default:
                            Image(systemName: "music.note")
                            
                        }
                    
                    }
                    VStack(alignment: .leading) {
                        Text(track.title)  // bold
                        Text("\(track.artist) — \(track.album)")  // secondary
                    }
                    Spacer()
                    Text(track.date)  // trailing
                }
                .onTapGesture(count:2) {
                    file?.title = track.title
                    file?.artist = track.artist
                    file?.album = track.album
                    file?.date = track.date
                    file?.spotifyId = track.spotifyId
                    file?.artworkUrl = track.artworkUrl
                    Task {
                        if let url = URL(string: track.artworkUrl),
                           let (data, _) = try? await URLSession.shared.data(from: url) {
                            file?.artworkData = data
                        }
                    }
                    dismiss()
                }
                
            }
        }
        .onAppear {
            query = (file?.title ?? "") + " " + (file?.artist ?? "")
        }

        
    }
}
