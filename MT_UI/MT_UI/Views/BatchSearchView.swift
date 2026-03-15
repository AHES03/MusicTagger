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
    @State private var selectedMatch: Int? = nil
    @State private var showingPopover: Bool = false
    @State private var popoverFile: MusicFile? = nil

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
                    Button(action: {
                        selectedMatch = i
                        popoverFile = matches[i].proposed ?? matches[i].original
                        showingPopover = true
                    }) {
                        HStack {
                            Toggle(isOn: $matches[i].confirmed, label: { Text("") })
                                .buttonStyle(.plain)
                            Text(URL(fileURLWithPath: matches[i].original.filePath).lastPathComponent)
                                .frame(width: 200)
                                .clipped()
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
                        .background(selectedMatch == i ? Color.accentColor.opacity(0.2) : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }

            // MARK: - Actions
            HStack {
                Spacer()
                Button("Apply") {
                    Task {
                        for i in matches {
                            if i.confirmed && i.proposed != nil {
                                do {
                                    try await APIClient.shared.writeMetadata(file: i.proposed!)
                                    if i.proposed?.artworkUrl != nil {
                                        try await APIClient.shared.writeArtwork(filePath: i.proposed!.filePath, artworkPath: i.proposed!.artworkUrl!)
                                    }
                                } catch {}
                            }
                        }
                        let confirmed = matches.filter { $0.confirmed && $0.proposed != nil }
                        let before = confirmed.map { $0.original }
                        let after = confirmed.map { $0.proposed! }
                        onApply(before, after)
                        dismiss()
                    }
                }
                .disabled(isSearching || matches.isEmpty)
            }
        } 
        .popover(isPresented: $showingPopover) {
            SpotifySearchView(file: $popoverFile)
        }
        .onChange(of: showingPopover) { _, isOpen in
            if !isOpen, let idx = selectedMatch, let updated = popoverFile {
                matches[idx].proposed = updated
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
                            proposed?.trackNumber = bestMatch.trackNumber
                            proposed?.date = bestMatch.date
                            proposed?.albumArtist = bestMatch.albumArtist
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
