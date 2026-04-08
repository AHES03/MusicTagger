import SwiftUI

/// Holds the original file alongside its best Spotify match and whether the user has confirmed it.
/// @Observable class (not struct) so SwiftUI reliably re-renders on nested property mutations.
@Observable @MainActor class BatchMatch: Identifiable, Hashable {
    var id: String {
        original.filePath
    }

    var original: MusicFile
    var proposed: MusicFile?
    var confirmed: Bool = true
    var isManuallyCorrected: Bool = false

    init(original: MusicFile, proposed: MusicFile? = nil, confirmed: Bool = true, isManuallyCorrected: Bool = false) {
        self.original = original
        self.proposed = proposed
        self.confirmed = confirmed
        self.isManuallyCorrected = isManuallyCorrected
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(original.filePath)
    }

    static func == (lhs: BatchMatch, rhs: BatchMatch) -> Bool {
        lhs.original.filePath == rhs.original.filePath
    }
}

struct BatchSearchView: View {
    @Binding var files: [MusicFile]
    var undoManager: UndoManager?
    var onApply: (_ before: [MusicFile], _ after: [MusicFile]) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var path = NavigationPath()
    @State private var matches: [BatchMatch] = []
    @State private var searchedCount: Int = 0
    @State private var isSearching: Bool = false
    @State private var isApplying: Bool = false
    @State private var tempFile: MusicFile?

    // TODO: compute field-level change count per match once inline editing is wired
    var totalChanges: Int {
        matches.filter { $0.proposed != nil }.count
    }

    var analysisStatus: StageStatus {
        isSearching ? .active : .completed
    }

    var reviewStatus: StageStatus {
        if isSearching { return .pending }
        if isApplying { return .completed }
        return .active
    }

    var applyingStatus: StageStatus {
        isApplying ? .active : .pending
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                // MARK: - Stage Tracker

                HStack(spacing: 0) {
                    StageIndicator(title: "ANALYSIS", status: analysisStatus)
                    StageDivider()
                    StageIndicator(title: "REVIEW", status: reviewStatus)
                    StageDivider()
                    StageIndicator(title: "APPLYING CHANGES", status: applyingStatus)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)

                if isSearching {
                    Text("Batch Search")
                        .font(.system(size: 24, weight: .bold))
                    Text("Searching \(searchedCount) / \(files.count)...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .padding(.bottom, 32)
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // MARK: - Title

                    Text("Batch Review")
                        .font(.system(size: 24, weight: .bold))
                    Text("Reviewing \(matches.count) files")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .padding(.bottom, 32)

                    // MARK: - Review List

                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(matches) { match in
                                CollapsibleTrackCard(match: match, onSearch: {
                                    // seed proposed from original before pushing
                                    if match.proposed == nil {
                                        match.proposed = match.original
                                    }
                                    tempFile = match.original
                                    path.append(match)
                                })
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }

                // MARK: - Footer

                VStack(spacing: 0) {
                    Divider().opacity(0.1)

                    HStack {
                        Button("Cancel") { dismiss() }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(width: 100)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("REVIEW SUMMARY")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("\(totalChanges) metadata updates pending")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 24)

                        Button("Apply All Changes") {
                            Task {
                                isApplying = true
                                await withTaskGroup(of: Void.self) { group in
                                    for match in matches {
                                        group.addTask {
                                            if await match.confirmed, let proposed = await match.proposed {
                                                do {
                                                    try await APIClient.shared.writeMetadata(file: proposed)
                                                    if proposed.artworkUrl != nil {
                                                        try await APIClient.shared.writeArtwork(filePath: proposed.filePath, artworkPath: proposed.artworkUrl!)
                                                    }
                                                } catch {}
                                            }
                                        }
                                    }
                                }
                                let confirmed = matches.filter { $0.confirmed && $0.proposed != nil }
                                let before = confirmed.map(\.original)
                                let after = confirmed.map { $0.proposed! }
                                onApply(before, after)
                                dismiss()
                                isApplying = false
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(width: 180)
                        .disabled(isSearching || matches.isEmpty || isApplying)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 24)
                    .background(Color(white: 0.12))
                }
            }

            // MARK: - Navigation Destination

            .navigationDestination(for: BatchMatch.self) { match in
                SearchSheetView(file: $tempFile)
                    .onDisappear {
                        match.proposed = tempFile
                        match.isManuallyCorrected = true
                    }
                    .navigationBarBackButtonHidden(true)
            }
        }
        .frame(width: 800, height: 700)
        .background(Color(white: 0.08).opacity(0.95))
        .background(.ultraThinMaterial)
        .overlay {
            if isApplying {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .onAppear {
            isSearching = true
            Task {
                await withTaskGroup(of: BatchMatch.self) { group in
                    for file in files {
                        group.addTask {
                            do {
                                let results = try await APIClient.shared.searchTracks(query: (file.title ?? "") + " " + (file.artist ?? ""))
                                var proposed: MusicFile?
                                if let bestMatch = results.first {
                                    proposed = file
                                    proposed?.title = bestMatch.title
                                    proposed?.artist = bestMatch.artist
                                    proposed?.album = bestMatch.album
                                    proposed?.trackNumber = bestMatch.trackNumber
                                    proposed?.date = bestMatch.date
                                    proposed?.albumArtist = bestMatch.albumArtist
                                    proposed?.artworkUrl = bestMatch.artworkUrl
                                    if let url = URL(string: bestMatch.artworkUrl) {
                                        if let (data, _) = try? await URLSession.shared.data(from: url) {
                                            proposed?.artworkData = data
                                        }
                                    }
                                }
                                return await BatchMatch(original: file, proposed: proposed)
                            } catch {
                                return await BatchMatch(original: file, proposed: nil)
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
    }
}

// MARK: - Track Card

struct CollapsibleTrackCard: View {
    var match: BatchMatch
    @State private var isExpanded = false
    @State private var isLoadingArtwork: Bool = false
    var onSearch: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header Row (Always Visible)
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.15))
                        .frame(width: 44, height: 44)
                        .task(id: match.proposed?.artworkUrl) {
                            await MainActor.run { isLoadingArtwork = true }
                            if let artworkUrl = match.proposed?.artworkUrl, let url = URL(string: artworkUrl) {
                                if let (data, _) = try? await URLSession.shared.data(from: url) {
                                    await MainActor.run {
                                        match.proposed?.artworkData = data
                                        isLoadingArtwork = false
                                    }
                                }
                            } else {
                                await MainActor.run { isLoadingArtwork = false }
                            }
                        }
                        .overlay(
                            Group {
                                if let data = match.proposed?.artworkData ?? match.original.artworkData,
                                   let nsImage = NSImage(data: data) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                            }
                        )
                        .overlay {
                            if isLoadingArtwork { ProgressView() }
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PROPOSED TITLE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(match.proposed?.title ?? match.original.title ?? "—")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(match.isManuallyCorrected ? .green : .blue)
                    }
                    .frame(width: 140, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PROPOSED ARTIST")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(match.proposed?.artist ?? match.original.artist ?? "—")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(width: 140, alignment: .leading)

                    if match.isManuallyCorrected {
                        Text("MANUAL")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(URL(fileURLWithPath: match.original.filePath).lastPathComponent)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundColor(.secondary)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            // MARK: - Expanded Content

            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider().opacity(0.1)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            InlineEditField(label: "TITLE", text: Binding(
                                get: { match.proposed?.title ?? match.original.title ?? "" },
                                set: { match.proposed?.title = $0 }
                            ))
                            InlineEditField(label: "ARTIST", text: Binding(
                                get: { match.proposed?.artist ?? match.original.artist ?? "" },
                                set: { match.proposed?.artist = $0 }
                            ))
                            InlineEditField(label: "ALBUM", text: Binding(
                                get: { match.proposed?.album ?? match.original.album ?? "" },
                                set: { match.proposed?.album = $0 }
                            ))
                        }
                        HStack(spacing: 12) {
                            InlineEditField(label: "DATE", text: Binding(
                                get: { match.proposed?.date ?? match.original.date ?? "" },
                                set: { match.proposed?.date = $0 }
                            ))
                            InlineEditField(label: "GENRE", text: Binding(
                                get: { match.proposed?.genre ?? match.original.genre ?? "" },
                                set: { match.proposed?.genre = $0 }
                            ))
                            InlineEditField(label: "COMMENT", text: Binding(
                                get: { match.proposed?.comment ?? match.original.comment ?? "" },
                                set: { match.proposed?.comment = $0 }
                            ))
                        }
                        HStack(spacing: 12) {
                            InlineEditField(label: "ALBUM ARTIST", text: Binding(
                                get: { match.proposed?.albumArtist ?? match.original.albumArtist ?? "" },
                                set: { match.proposed?.albumArtist = $0 }
                            ))
                            InlineEditField(label: "COMPOSER", text: Binding(
                                get: { match.proposed?.composer ?? match.original.composer ?? "" },
                                set: { match.proposed?.composer = $0 }
                            ))
                            Button(action: onSearch) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Search Match")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 14)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .background(Color.white.opacity(0.02))
            }
        }
        .background(Color(white: 0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Batch Search Destination

struct BatchSearchDestination: View {
    var match: BatchMatch
    @State private var tempFile: MusicFile?

    var body: some View {
        SearchSheetView(file: $tempFile)
            .onAppear { tempFile = match.original }
            .onDisappear { match.proposed = tempFile }
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Inline Edit Field

struct InlineEditField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .padding(6)
                .background(Color(white: 0.15))
                .cornerRadius(4)
        }
    }
}

// MARK: - Stage Tracker Components

enum StageStatus { case completed, active, pending }

struct StageIndicator: View {
    let title: String
    let status: StageStatus

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status == .pending ? Color.gray.opacity(0.3) : Color.blue)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: status == .active ? 4 : 0)
                )
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(status == .active ? .primary : .secondary)
        }
    }
}

struct StageDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 60, height: 1)
            .padding(.horizontal, 16)
    }
}
