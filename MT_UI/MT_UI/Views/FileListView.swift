// Displays the list of local music files the user has imported.
// Allows selecting a file to view/edit its metadata.
// Right panel in the two-panel layout. Matches the table in Example.png.

import SwiftUI

// TODO: Create a FileListView struct conforming to View.
//       Receives `files: [MusicFile]` and a `selection: Binding<MusicFile?>` from ContentView.

// TODO: Use SwiftUI Table (macOS 12+) to display files in columns:
//         Table(files, selection: $selection) {
//             TableColumn("Filename") { ... }
//             TableColumn("Path")     { ... }
//             TableColumn("Tag")      { ... }  // Tag status indicator (e.g. has metadata or not)
//             TableColumn("Title")    { ... }
//             TableColumn("Track")    { ... }
//             TableColumn("Artist")   { ... }
//             TableColumn("Album")    { ... }
//         }
//       Column widths should be resizable. Match ordering from Example.png.

// TODO: Apply .alternatingRowBackgrounds() for the striped dark row appearance in Example.png.

// TODO: Support multi-selection if bulk editing is a future goal (Table supports Set<MusicFile.ID>).
//       For now, single selection (MusicFile.ID?) is sufficient.

// TODO: When selection changes, call APIClient.readMetadata(filePath: selectedFile.filePath)
//       and update the selected file's metadata fields.
//       Show a loading indicator during the async call.

// TODO: Support drag-and-drop import of audio files:
//         .dropDestination(for: URL.self) { urls, _ in ... }
//       Filter dropped URLs to supported extensions: .flac, .mp3, .m4a, .aac, .wav
//       For each valid URL, call APIClient.readMetadata() and append to files list.

// TODO: Right-click context menu on a row:
//         - "Remove from list" (does not delete the file from disk)
//         - "Show in Finder" (NSWorkspace.shared.activateFileViewerSelecting)

// TODO: Show an empty state placeholder when `files` is empty:
//         "Drop audio files here or use the toolbar to open files."
