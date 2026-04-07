import SwiftUI

// Holds the original file alongside its best Spotify match and whether the user has confirmed it.
struct BatchMatch: Sendable {
    var original: MusicFile
    var proposed: MusicFile?
    var confirmed: Bool = true
}

struct BatchItem: Identifiable {
    let id: String // uses filePath as stable identity
    let title: String
    let artist: String
    let album: String
    let filename: String
    let changes: [MetadataChange]
}

struct MetadataChange: Identifiable {
    let id = UUID()
    let field: String
    let current: String
    let proposed: String
    var hasConflict: Bool = false
}

struct BatchSearchView: View {
    @Binding var files: [MusicFile]
    var undoManager: UndoManager?
    var onApply: (_ before: [MusicFile], _ after: [MusicFile]) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var matches: [BatchMatch] = []
    @State private var searchedCount: Int = 0
    @State private var isSearching: Bool = false
    @State private var isApplying: Bool = false
    @State private var expandedItems: Set<String> = []

    // Maps BatchMatch → BatchItem by diffing original vs proposed fields.
    var batchItems: [BatchItem] {
        matches.map { match in
            let original = match.original
            let proposed = match.proposed
            var changes: [MetadataChange] = []
            if let proposed = proposed {
                func check(_ field: String, _ a: String?, _ b: String?) {
                    if (a ?? "") != (b ?? "") {
                        changes.append(MetadataChange(field: field, current: a ?? "—", proposed: b ?? "—"))
                    }
                }
                check("Title", original.title, proposed.title)
                check("Artist", original.artist, proposed.artist)
                check("Album", original.album, proposed.album)
                check("Date", original.date, proposed.date)
                check("Album Artist", original.albumArtist, proposed.albumArtist)
                check("Track No", original.trackNumber.map(String.init), proposed.trackNumber.map(String.init))
            }
            return BatchItem(
                id: original.filePath,
                title: proposed?.title ?? original.title ?? "—",
                artist: proposed?.artist ?? original.artist ?? "—",
                album: proposed?.album ?? original.album ?? "—",
                filename: URL(fileURLWithPath: original.filePath).lastPathComponent,
                changes: changes
            )
        }
    }

    var totalChanges: Int { batchItems.reduce(0) { $0 + $1.changes.count } }

    var analysisStatus: StageStatus { isSearching ? .active : .completed }
    var reviewStatus: StageStatus {
        if isSearching { return .pending }
        if isApplying { return .completed }
        return .active
    }
    var applyingStatus: StageStatus { isApplying ? .active : .pending }

    var body: some View {
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
                        ForEach(batchItems) { item in
                            CollapsibleTrackCard(
                                item: item,
                                isExpanded: expandedItems.contains(item.id),
                                onToggle: {
                                    if expandedItems.contains(item.id) {
                                        expandedItems.remove(item.id)
                                    } else {
                                        expandedItems.insert(item.id)
                                    }
                                }
                            )
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
                        .buttonStyle(PlainButtonStyle())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

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
                                        if match.confirmed, let proposed = match.proposed {
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
                            let before = confirmed.map { $0.original }
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
                .background(Color(white: 0.05))
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
    }
}

// MARK: - Track Card
struct CollapsibleTrackCard: View {
    let item: BatchItem
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header Row (Always Visible)
            Button(action: onToggle) {
                HStack(spacing: 16) {
                    // TODO: replace placeholder with AsyncImage using proposed artworkUrl once BatchItem exposes it
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(white: 0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PROPOSED TITLE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(item.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 120, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PROPOSED ARTIST")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(item.artist)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(width: 140, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PROPOSED ALBUM")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(item.album)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(item.changes.contains(where: { $0.field == "Album" }) ? .blue : .primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.filename)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("\(item.changes.count) change\(item.changes.count == 1 ? "" : "s")")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.6))
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundColor(.secondary)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            // MARK: - Expanded Changes Table
            if isExpanded {
                VStack(spacing: 0) {
                    Divider().opacity(0.1)

                    HStack {
                        Text("FIELD").frame(width: 120, alignment: .leading)
                        Text("CURRENT VALUE").frame(width: 200, alignment: .leading)
                        Text("PROPOSED VALUE").frame(width: 200, alignment: .leading)
                        Spacer()
                        Text("STATUS").frame(width: 60, alignment: .trailing)
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    ForEach(item.changes) { change in
                        HStack {
                            Text(change.field.uppercased())
                                .font(.system(size: 10, weight: .medium))
                                .frame(width: 120, alignment: .leading)
                            Text(change.current)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .italic()
                                .frame(width: 200, alignment: .leading)
                            Text(change.proposed)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(change.hasConflict ? .orange : .green)
                                .frame(width: 200, alignment: .leading)
                            Spacer()
                            Image(systemName: change.hasConflict ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundColor(change.hasConflict ? .orange : .green)
                                .font(.system(size: 12))
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                    }
                    .padding(.bottom, 16)
                }
                .background(Color(white: 0.1).opacity(0.3))
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
