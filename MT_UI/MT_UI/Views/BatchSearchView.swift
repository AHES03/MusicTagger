// Batch Spotify search sheet.
// Takes all loaded files, auto-searches Spotify for each, lets the user review matches, then saves in one undo group.
// Displayed as a .sheet() from ContentView via the wand toolbar button.

import SwiftUI

// Holds the original file alongside its best Spotify match and whether the user has confirmed it.
struct BatchMatch {
    var original: MusicFile
    // TODO: Phase 1 — populate proposed with the first result from APIClient.searchTracks.
    var proposed: MusicFile?
    var confirmed: Bool = true
}

struct BatchSearchView: View {
    @Binding var files: [MusicFile]
    var undoManager: UndoManager?
    // Called after Apply — passes parallel arrays of before/after states up to ContentView for undo registration.
    var onApply: (_ before: [MusicFile], _ after: [MusicFile]) -> Void
    @Environment(\.dismiss) var dismiss

    // TODO: Phase 1 — replace with @State private var matches: [BatchMatch] = []
    // Populated during auto-search on appear.
    @State private var matches: [BatchMatch] = []

    // TODO: Phase 1 — track search progress for the progress indicator.
    // Increment after each file's search completes.
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
            // TODO: Phase 1 — show this while isSearching is true.
            // Display "Searching \(searchedCount) / \(files.count)..." and a ProgressView.
            if isSearching {
                HStack {
                    ProgressView()
                    Text("Searching \(searchedCount) / \(files.count)...")
                }
            }

            // TODO: Phase 2 — replace with a review table showing each match row.
            // For now, just a placeholder.
            Spacer()
            Text("Results will appear here after search.")
                .foregroundStyle(.secondary)
            Spacer()

            // MARK: - Actions
            // TODO: Phase 3 — implement Apply: call undoManager?.beginUndoGrouping(), write each confirmed match,
            // register undo for each via MetadataUndoService.shared.registerSave, call endUndoGrouping(), then onApply + dismiss.
            HStack {
                Spacer()
                Button("Apply") {
                    // TODO: Phase 3
                }
                .disabled(isSearching || matches.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            // TODO: Phase 1 — kick off auto-search here.
            // Loop through files, call searchTracks(query: title + artist) for each,
            // take the first result, build a proposed MusicFile from the Track,
            // append a BatchMatch to matches, and increment searchedCount.
            // Set isSearching = true before the loop and false when done.
        }
    }
}
