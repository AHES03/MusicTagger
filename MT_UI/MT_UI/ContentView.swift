// Root view. Composes the file list panel and metadata editor panel side by side.
// Matches the two-panel layout visible in Example.png.

import SwiftUI


// State: files (imported file list) and selectedFile (current selection) owned here
// and passed down as bindings to child views.
// TODO: Add toolbar — open files button, save button.
// TODO: Handle drag-and-drop at this level or delegate to FileListView.

struct ContentView: View {
    @State private var selectedFile: MusicFile?
    @State private var files: [MusicFile] = []
    var body: some View {
        HSplitView {
            MetadataEditorView(file: $selectedFile)
                .frame(minWidth: 200, maxWidth: 200)
                .frame(maxHeight: .infinity)
            FileListView(files: $files, onSelect: $selectedFile)
                .frame(maxWidth:
                  .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
