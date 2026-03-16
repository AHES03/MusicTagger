// Batch Spotify search sheet.
// Takes all loaded files, auto-searches Spotify for each, lets the user review matches, then saves in one undo group.
// Displayed as a .sheet() from ContentView via the wand toolbar button.

import SwiftUI

// Identifiable wrapper for a row index — used with .popover(item:) to anchor the popover to the tapped row.
struct PopoverMatch: Identifiable, Equatable {
    let id: Int
}

// Holds the original file alongside its best Spotify match and whether the user has confirmed it.
struct BatchMatch: Sendable {
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
    @State private var popoverItem: PopoverMatch? = nil
    @State private var popoverFile: MusicFile? = nil
    @State private var isApplying: Bool = false

    var body: some View {
        ZStack{
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
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(matches.indices, id: \.self) { i in
                            Button(action: {
                                selectedMatch = i
                                popoverFile = matches[i].proposed ?? matches[i].original
                                popoverItem = PopoverMatch(id: i)
                            }) {
                                HStack {
                                    Toggle(isOn: $matches[i].confirmed, label: { Text("") })
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
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                                .background(selectedMatch == i ? Color.accentColor.opacity(0.2) : (i % 2 == 0 ? Color.clear : Color.primary.opacity(0.04)))
                            }
                            .buttonStyle(.plain)
                            .popover(item: $popoverItem) { _ in
                                SpotifySearchView(file: $popoverFile)
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 500)
                .border(Color.primary.opacity(0.1))
                .layoutPriority(1)
                // MARK: - Actions
                HStack {
                    Spacer()
                    Button("Apply") {
                        Task {
                            // TODO: Replace sequential for loop with withTaskGroup(of: Void.self) to run all writes concurrently.
                            // Each child task handles one confirmed match: writeMetadata then writeArtwork if artworkUrl is set.
                            // onApply and dismiss() stay after the group — withTaskGroup waits for all child tasks before continuing.
                            isApplying = true
                            await withTaskGroup(of:  Void.self) { group in
                                for file in matches{
                                    group.addTask {
                                        if file.confirmed && file.proposed != nil {
                                            do {
                                                try await APIClient.shared.writeMetadata(file: file.proposed!)
                                                if file.proposed?.artworkUrl != nil {
                                                    try await APIClient.shared.writeArtwork(filePath: file.proposed!.filePath, artworkPath: file.proposed!.artworkUrl!)
                                                }
                                            } catch {}
                                        }
                                    }
                                }
                                
                            }
                            let confirmed = matches.filter { $0.confirmed && $0.proposed != nil }
                            let before = confirmed.map { $0.original }
                            let after = confirmed.map { $0.proposed! }
                            onApply(before, after)
                            dismiss()
                            isApplying = false
                        }
                    }
                    .disabled(isSearching || matches.isEmpty)
                }
            }
            .onChange(of: popoverItem) { _, item in
                if item == nil, let idx = selectedMatch, let updated = popoverFile {
                    matches[idx].proposed = updated
                }
            }
            .padding()
            .frame(minWidth: 700, minHeight: 500)
            .onAppear {
                isSearching = true
                Task {
                    
                    await withTaskGroup(of: BatchMatch.self) { group in
                        for file in files{
                            group.addTask {
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
                                        proposed?.artworkUrl = bestMatch.artworkUrl
                                    }
                                    return BatchMatch(original: file, proposed: proposed)
         
                                    
                                } catch {
                                    return BatchMatch(original: file, proposed: nil)
                                }
                            }
                            
                        }
                        for await result in group {
                            matches.append(result)
                            searchedCount += 1
                        }
                            
                
                        
                    }
                    isSearching = false
                }
            }
            if isApplying{
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }

    }
}
