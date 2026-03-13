// Displays the list of local music files the user has imported.
// Allows selecting a file to view/edit its metadata.
// Right panel in the two-panel layout. Matches the table in Example.png.

import SwiftUI
import AppKit
struct FileListView: View {
    @Binding var files: [MusicFile]
    @Binding var onSelect: MusicFile?
    @State private var selection: MusicFile.ID?
    var body: some View {
        Table(files, selection:$selection){
            
            TableColumn("Title")    {file in Text( file.title ?? "(no title)" )}
            TableColumn("Track #")     {file in Text(file.trackNumber.map { String($0) } ?? "")}
            TableColumn("Artist")    {file in Text( file.artist ?? "" )}
            TableColumn("Album")     {file in Text(file.album ?? "" )}
            
        }
        .alternatingRowBackgrounds(.enabled)
        .contextMenu {
            Button("Remove from list") {
                guard let id = selection else { return }
                files.removeAll(where: { $0.id == id})
            }
            Button("Show in Finder") {
                guard let id = selection else { return }
                guard let file = files.first(where: {$0.id == id }) else { return }
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.filePath)])
            }
        }
        .dropDestination(for: URL.self, action: { urls, _ in
            for url in urls {
                if ["flac", "mp3", "m4a", "aac", "wav"].contains(url.pathExtension) {
                    Task {
                        do{
                            files.append(try await APIClient.shared.readMetadata(filePath: url.path))
                        }catch{
                            
                        }
                    }
                }
            }
            return true
        })
        .onChange(of: selection) { _, newValue in
            guard let id = newValue else { return }
            guard let file = files.first(where: {$0.id == id }) else { return }
            let url = URL(fileURLWithPath: file.filePath)
            Task{
                do{
                     let updated = try await APIClient.shared.readMetadata(filePath: url.path)
                     onSelect = updated
                 }catch{
                     
                 }
            }
        }
        .overlay { if files.isEmpty { Text("Drop audio files here or use the toolbar to open files.").frame(maxWidth: .infinity, maxHeight: .infinity) } }
    }

    // Single selection (MusicFile.ID?) — multi-selection can be added later via Set<MusicFile.ID>.
    // Selection changes call APIClient.readMetadata and update onSelect with fresh metadata.
    // Drag-and-drop filters by audio extension and appends each file via APIClient.readMetadata.

    // Empty state overlay shown when no files have been imported yet.

}

