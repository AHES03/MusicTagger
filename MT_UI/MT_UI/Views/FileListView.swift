// Displays the list of local music files the user has imported.
// Allows selecting a file to view/edit its metadata.
// Right panel in the two-panel layout. Matches the table in Example.png.

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - AppKit drop receiver
// SwiftUI Table intercepts drag events, so we use an NSViewRepresentable
// as a background to register for drag types at the AppKit level.
private struct FileDropReceiver: NSViewRepresentable {
    var onDrop: ([URL]) -> Void

    func makeNSView(context: Context) -> DropNSView {
        let view = DropNSView()
        view.onDrop = onDrop
        return view
    }

    func updateNSView(_ nsView: DropNSView, context: Context) {
        nsView.onDrop = onDrop
    }

    class DropNSView: NSView {
        var onDrop: (([URL]) -> Void)?

        override init(frame: NSRect) {
            super.init(frame: frame)
            registerForDraggedTypes([.fileURL])
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            registerForDraggedTypes([.fileURL])
        }

        override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

        override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else { return false }
            onDrop?(urls)
            return true
        }
    }
}
struct FileListView: View {
    @Binding var files: [MusicFile]
    @Binding var onSelect: MusicFile?
    var displayedFiles: [MusicFile]
    @State private var sortOrder: [KeyPathComparator<MusicFile>] = []
    @State private var previousSortOrder: [KeyPathComparator<MusicFile>] = []
    @State private var selection: MusicFile.ID?

    var body: some View {
        if displayedFiles.isEmpty {
            VStack{
                Image(systemName: "music.note.square.stack").font(Font.system(size: 140))
                Text("Drop audio files here or use the toolbar to open files.")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    FileDropReceiver { urls in
                        for url in urls {
                            let ext = url.pathExtension.lowercased()
                            if ["flac", "mp3", "m4a", "aac", "wav"].contains(ext) {
                                Task { @MainActor in
                                    do {
                                        files.append(try await APIClient.shared.readMetadata(filePath: url.path))
                                    } catch {}
                                }
                            }
                        }
                    }
                )
        }
        else{
            let artworkCol = TableColumn("") { (file: MusicFile) in
                Group {
                    if let data = file.artworkData, let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage).resizable().frame(width: 30, height: 30)
                    } else {
                        Image(systemName: "music.note")
                    }
                }
            }
            let titleCol = TableColumn("Title", value: \MusicFile.sortTitle) { (file: MusicFile) in Text(file.title ?? "(no title)") }
            let trackCol = TableColumn("Track #", value: \MusicFile.sortTrackNumber) { (file: MusicFile) in Text(file.trackNumber.map { String($0) } ?? "") }
            let artistCol = TableColumn("Artist", value: \MusicFile.sortArtist) { (file: MusicFile) in Text(file.artist ?? "") }
            let albumCol = TableColumn("Album", value: \MusicFile.sortAlbum) { (file: MusicFile) in Text(file.album ?? "") }
            Table(displayedFiles.sorted(using: sortOrder), selection: $selection, sortOrder: $sortOrder) {
                artworkCol.width(40)
                titleCol
                trackCol
                artistCol
                albumCol
            }
            .alternatingRowBackgrounds(.enabled)
            .contextMenu {
                Button("Remove from list") {
                    guard let id = selection else { return }
                    files.removeAll(where: { $0.id == id })
                    selection = nil
                    onSelect = nil
                }
                Button("Show in Finder") {
                    guard let id = selection else { return }
                    guard let file = files.first(where: { $0.id == id }) else { return }
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.filePath)])
                }
            }
            // TODO: Add .onChange(of: sortOrder) to detect third click (new order is .forward and previous was .reverse for same column).
            // If third click detected, set sortOrder = [] to clear. Otherwise set previousSortOrder = sortOrder.
            .onChange(of: sortOrder) {oldValue, newValue in
                if newValue.first?.order == .forward && oldValue.first?.order == .reverse{
                    sortOrder = []
                }else{
                    previousSortOrder = newValue
                } }
            .onChange(of: selection) { _, newValue in
                guard let id = newValue else { onSelect = nil; return }
                guard let file = files.first(where: { $0.id == id }) else { return }
                Task {
                    do {
                        onSelect = try await APIClient.shared.readMetadata(filePath: file.filePath)
                    } catch {}
                }
            }
        }

    }

}

