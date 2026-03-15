// Batch Spotify search sheet.
// Takes all loaded files, auto-searches Spotify for each, lets the user review matches, then saves in one undo group.
// Displayed as a .sheet() from ContentView via the wand toolbar button.

import SwiftUI

// Holds the original file alongside its best Spotify match and whether the user has confirmed it.
struct BatchMatch {
    var original: MusicFile
    var proposed: MusicFile?
    var confirmed: Bool = true
}

struct BatchSearchView: View {
    @Binding var files: [MusicFile]
    var undoManager: UndoManager?
    // Called after Apply — passes parallel arrays of before/after states up to ContentView for undo registration.
    var onApply: (_ before: [MusicFile], _ after: [MusicFile]) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var matches: [BatchMatch] = []
    @State private var searchedCount: Int = 0
    @State private var isSearching: Bool = false

    var body: some View {
        VStack {

            // MARK: - Header
            HStack {
                Text("Batch Search").font(.title2)
                Spacer()
                Button("Cancel") { dismiss() }
            }

            // MARK: - Progress
            if isSearching {
                HStack {
                    ProgressView()
                    Text("Searching \(searchedCount) / \(files.count)...")
                }
            }

            // Review table — one row per file showing original filename, proposed Spotify match, and a confirmation toggle.
            List {
                ForEach(matches.indices, id: \.self) { i in
                    HStack {
                        Toggle(isOn: $matches[i].confirmed, label: { Text("") })
                        Text(URL(fileURLWithPath: matches[i].original.filePath).lastPathComponent)
                        if let proposed = matches[i].proposed {
                            AsyncImage(url: URL(string: proposed.artworkUrl ?? "")) { phase in
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
                                Text(proposed.title ?? "")
                                Text(proposed.artist ?? "")
                                Text(proposed.album ?? "")
                            }
                        } else {
                            Text("No result found").foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // MARK: - Actions
            HStack {
                Spacer()
                Button("Apply") {
                    undoManager?.beginUndoGrouping()
                    Task{
                        for i in matches{
                            if i.confirmed && i.proposed != nil{
                                do{
                                    try await APIClient.shared.writeMetadata(file: i.proposed!)
                                    if i.proposed?.artworkUrl != nil {
                                        try await APIClient.shared.writeArtwork(filePath: i.proposed!.filePath, artworkPath: i.proposed!.artworkUrl!)
                                    }
                                }catch{
                                    
                                }
                                
                                MetadataUndoService.shared.registerSave(before: i.original,after: i.proposed!,onComplete: { _ in }, undoManager: undoManager)
                            }
                        }
                        let confirmed = matches.filter { $0.confirmed && $0.proposed != nil }
                        let before = confirmed.map { $0.original }
                        let after = confirmed.map { $0.proposed! }
                        undoManager?.endUndoGrouping()
                        
                        onApply(before, after )
                        dismiss()
                    }
                }
                .disabled(isSearching || matches.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            isSearching = true
            Task {
                for file in files {
                    do {
                        let results = try await APIClient.shared.searchTracks(query: (file.title ?? "") + " " + (file.artist ?? ""))
                        var proposed: MusicFile? = nil
                        if let bestMatch = results.first {
                            proposed = file
                            proposed?.title = bestMatch.title
                            proposed?.artist = bestMatch.artist
                            proposed?.album = bestMatch.album
                            // TODO: populate proposed?.trackNumber once backend /search returns track_number in SpotifyTrack.
                            proposed?.date = bestMatch.date
                            // TODO: Add Album artist proposed?.albumArtist = bestMatch
                            proposed?.spotifyId = bestMatch.id
                            proposed?.artworkUrl = bestMatch.artworkUrl
                        }
                        matches.append(BatchMatch(original: file, proposed: proposed))
                        searchedCount += 1
                    } catch {}
                }
                isSearching = false
            }
        }
    }
}
