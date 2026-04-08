// Search sheet/modal for querying Spotify or iTunes.
// Displayed as a .sheet() from MetadataEditorView.
// Displays a list of matching tracks; selecting one populates the metadata editor.
// iTunes picker option is present but not yet implemented — defaults to Spotify.

import SwiftUI

struct SearchResultRow: View {
    let result: Track
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: result.artworkUrl)) { phase in
                switch phase {
                case .empty: ProgressView().frame(width: 44, height: 44)
                case let .success(image): image.resizable().scaledToFill().frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 6))
                case .failure: Image(systemName: "music.note").frame(width: 44, height: 44)
                @unknown default: Image(systemName: "music.note").frame(width: 44, height: 44)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title).font(.body).fontWeight(.medium)
                Text("\(result.artist) — \(result.album)").font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Text(result.date).font(.subheadline).foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
    }
}

struct SearchSheetView: View {
    @Binding var file: MusicFile?
    @Environment(\.dismiss) var dismiss
    @State private var searchSource = 0 // 0 = Spotify, 1 = iTunes (not yet implemented)
    @State private var searchQuery: String = ""
    @State private var searchResults: [Track] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedResultID: Track.ID?

    func searchSpotify(query: String) {
        Task {
            do {
                isLoading = true
                searchResults = try await APIClient.shared.searchTracksSpotify(query: query)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func searchItunes(query: String) {
        Task {
            do {
                isLoading = true
                searchResults = try await APIClient.shared.searchTracksItunes(query: query)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func search(query: String) {
        if searchSource == 0 {
            searchSpotify(query: query)
        } else {
            searchItunes(query: query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Source picker — iTunes not yet implemented, defaults to Spotify
            HStack(spacing: 12) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search by Artist, Album, or Track title...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit { search(query: searchQuery) }
                }
                .padding(10)
                .background(Color(white: 0.12))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

                // Source Pop-up (No Label)
                Picker("", selection: $searchSource) {
                    Text("Spotify").tag(0)
                    Text("iTunes").tag(1)
                }
                .pickerStyle(.menu)
                .frame(width: 100)

                // Search Button
                Button("Search") {
                    search(query: searchQuery)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 80)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()
                .opacity(0.1)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResults.isEmpty, !searchQuery.isEmpty {
                Text("No results for \"\(searchQuery)\"")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Results List with Single Selection
                List(searchResults, selection: $selectedResultID) { result in
                    SearchResultRow(result: result, isSelected: selectedResultID == result.id)
                        .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
                        .listRowBackground(selectedResultID == result.id ? Color.blue.opacity(0.1) : Color.clear)
                        .onTapGesture {
                            selectedResultID = result.id
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            Divider()
                .opacity(0.1)

            // Footer
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("\(searchResults.count) RESULTS FOUND ON \(searchSource == 0 ? "SPOTIFY" : "ITUNES")")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.secondary)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(width: 80)

                Button("Select") {
                    guard let id = selectedResultID,
                          let track = searchResults.first(where: { $0.id == id }) else { return }
                    file?.title = track.title
                    file?.artist = track.artist
                    file?.album = track.album
                    file?.date = track.date
                    file?.trackNumber = track.trackNumber
                    file?.albumArtist = track.albumArtist
                    file?.genre = track.genre
                    file?.artworkUrl = track.artworkUrl
                    Task {
                        if let url = URL(string: track.artworkUrl),
                           let (data, _) = try? await URLSession.shared.data(from: url) {
                            file?.artworkData = data
                        }
                    }
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 100)
                .disabled(selectedResultID == nil)
                .opacity(selectedResultID == nil ? 0.5 : 1.0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 700, height: 600)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            searchQuery = (file?.title ?? "") + " " + (file?.artist ?? "")
            search(query: searchQuery)
        }
        .onChange(of: searchSource) {
            search(query: searchQuery)
        }
    }
}
