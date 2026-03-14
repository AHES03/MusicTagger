// Root view. Composes the file list panel and metadata editor panel side by side.
// Matches the two-panel layout visible in Example.png.

import SwiftUI
import UniformTypeIdentifiers


// State: files (imported file list) and selectedFile (current selection) owned here
// and passed down as bindings to child views.

struct ContentView: View {
    @State private var selectedFile: MusicFile?
    @State private var files: [MusicFile] = []
    var body: some View {
        HSplitView {
            MetadataEditorView(file: $selectedFile, onSave:{ updated in
                     guard let index = files.firstIndex(where: { $0.id == updated.id }) else { return }
                     files[index] = updated
                 })
                .frame(minWidth: 200, maxWidth: .infinity)
                .frame(maxHeight: .infinity)
            FileListView(files: $files, onSelect: $selectedFile)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minWidth: 800)
        }
        .frame(minWidth: 800, minHeight: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem {
                Button("Open Files") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = true
                    // TODO: Set canChooseDirectories = true and canChooseFiles = true so user can pick a folder or individual files.
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.audio]
                    guard panel.runModal() == .OK else { return }
                    for url in panel.urls {
                        // TODO: Replace this loop body with a call to a recursive helper function.
                        // The helper should:
                        //   - Accept a URL and a current depth (Int), max depth = 2
                        //   - Use FileManager.default.contentsOfDirectory(at:) to list contents
                        //   - For each item: if it's an audio file (check pathExtension against ["flac","mp3","m4a","aac","wav"]), call readMetadata and append to files
                        //   - If it's a directory and depth < 2, recurse with depth + 1
                        //   - If the picked URL is a file (not a directory), call readMetadata directly without recursing
                        Task {
                            do {
                                files.append(try await APIClient.shared.readMetadata(filePath: url.path))
                            } catch {}
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
