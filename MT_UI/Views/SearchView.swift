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
    @State private var selectedTrack: Track.ID?
    
    func searchSpotify(query:String){
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
    
    var body: some View {
        
        VStack {
            // MARK: - Search Bar
            // Pre-filled with file title + artist on appear.
            HStack {
                TextField("Search", text: $query)
                    .onSubmit { searchSpotify(query: query) }
                Button("Search") {
                    searchSpotify(query: query)
                }
                Button("Cancel") { dismiss() }
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
            List(results, selection: $selectedTrack) {track in
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
                .contentShape(Rectangle())
                .onTapGesture(count: 1) {
                    if track.id == selectedTrack {
                        file?.title = track.title
                        file?.artist = track.artist
                        file?.album = track.album
                        file?.date = track.date
                        file?.trackNumber = track.trackNumber
                        file?.albumArtist = track.albumArtist
                        file?.artworkUrl = track.artworkUrl
                        Task {
                            if let url = URL(string: track.artworkUrl),
                               let (data, _) = try? await URLSession.shared.data(from: url) {
                                file?.artworkData = data
                            }
                        }
                        dismiss()
                    
                    }else { selectedTrack = track.id }
                }
                
            }
        }
        .frame(minWidth: 600, minHeight:
          400)
        .padding()
        .onAppear {
            query = (file?.title ?? "") + " " + (file?.artist ?? "")
            searchSpotify(query: query)
            
        }

        
    }
}
