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
    @State private var selection: MusicFile.ID?
    var body: some View {
        // TODO: Empty state — replace .overlay with a conditional: show plain Text placeholder when files.isEmpty, Table only when files exist (avoids rendering the scroll view when empty).
        if files.isEmpty {
            Text("Drop audio files here or use the toolbar to open files.").frame(maxWidth: .infinity, maxHeight: .infinity)
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
            Table(files, selection: $selection) {
                TableColumn("Title")  { file in Text(file.title ?? "(no title)") }
                TableColumn("Track #") { file in Text(file.trackNumber.map { String($0) } ?? "") }
                TableColumn("Artist") { file in Text(file.artist ?? "") }
                TableColumn("Album")  { file in Text(file.album ?? "") }
            }
            .alternatingRowBackgrounds(.enabled)
            .contextMenu {
                Button("Remove from list") {
                    guard let id = selection else { return }
                    files.removeAll(where: { $0.id == id })
                }
                Button("Show in Finder") {
                    guard let id = selection else { return }
                    guard let file = files.first(where: { $0.id == id }) else { return }
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.filePath)])
                }
            }
            .onChange(of: selection) { _, newValue in
                guard let id = newValue else { return }
                guard let file = files.first(where: { $0.id == id }) else { return }
                Task {
                    do {
                        onSelect = try await APIClient.shared.readMetadata(filePath: file.filePath)
                    } catch {}
                }
            }
        }

    }

    // Single selection (MusicFile.ID?) — multi-selection can be added later via Set<MusicFile.ID>.
    // Selection changes call APIClient.readMetadata and update onSelect with fresh metadata.
    // TODO: Drag-and-drop — SwiftUI Table consumes all drag events; requires AppKit NSTableView integration to implement reliably.
    // Empty state overlay shown when no files have been imported yet.

}

