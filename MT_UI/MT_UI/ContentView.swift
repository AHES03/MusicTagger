// Root view. Composes the file list panel and metadata editor panel side by side.
// Matches the two-panel layout visible in Example.png.

import SwiftUI

// TODO: Hold shared app state here (or in a ViewModel/@EnvironmentObject):
//         - files: [MusicFile]  — the list of imported files
//         - selectedFile: MusicFile?  — the currently selected file
//       These are passed down to child views.

// TODO: Body should be an HSplitView (or NavigationSplitView) with two panels:
//
//         HSplitView {
//             MetadataEditorView(...)   // Left panel — fixed ~200pt width
//             FileListView(...)         // Right panel — fills remaining space
//         }
//
//       Set the left panel's frame to a fixed or min width (~200pt) matching the screenshot.

// TODO: Add a macOS toolbar (`.toolbar { }`) above the right panel with:
//         - Open folder / add files button
//         - Save / write metadata button
//         - Any other actions from Example.png (the icon strip across the top right)

// TODO: Apply .frame(minWidth: 800, minHeight: 500) or equivalent window constraints.

// TODO: Handle drag-and-drop of audio files onto the window at this level,
//       or delegate it to FileListView. On drop, call APIClient.readMetadata()
//       for each dropped file and append to `files`.

struct ContentView: View {
    var body: some View {
        // TODO: Replace with HSplitView containing MetadataEditorView and FileListView
        Text("Hello, world!")
    }
}

#Preview {
    ContentView()
}
