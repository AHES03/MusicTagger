// Root view. Composes the file list panel and metadata editor panel side by side.
// Matches the two-panel layout visible in Example.png.

import SwiftUI
import UniformTypeIdentifiers


// State: files (imported file list) and selectedFile (current selection) owned here
// and passed down as bindings to child views.

struct ContentView: View {
    @State private var selectedFile: MusicFile?
    @State private var files: [MusicFile] = []
    // TODO: Add @State var searchQuery: String = "" for list search filtering.
    // TODO: Add @State var showingBatchSearch: Bool = false for batch search sheet.
    @State var searchQuery: String = ""
    @State var isSearching: Bool = false
    @State var showingBatchSearch: Bool = false
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
            // TODO: Replace button label with Image(systemName: "folder.badge.plus") for Add Files icon.
            ToolbarItem {
                Button(action:{
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = true
                    panel.allowedContentTypes = [.audio]
                    guard panel.runModal() == .OK else { return }
                    func importURL(_ url: URL, depth: Int){
                        let isDirectory =  (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                        let isAudio =  ["flac", "mp3", "m4a", "aac",
                                        "wav"].contains(url.pathExtension.lowercased())
                        if isDirectory && depth < 2{
                            let childUrls = (try? FileManager.default.contentsOfDirectory(at:
                                                                                            url, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
                            for childUrl in childUrls{
                                importURL(childUrl, depth: depth + 1)
                            }
                        }else if  isAudio {
                                Task {@MainActor in
                                    do {
                                        files.append(try await APIClient.shared.readMetadata(filePath: url.path))
                                    } catch {}
                                }
                            }
                        }
                    
                    for url in panel.urls {
                        importURL(url, depth: 0)
                    }
                }
                ) {
                    Image(systemName: "folder.badge.plus")
                }
            }
            ToolbarItem{
                if isSearching{
                    TextField("Search",
                              text:$searchQuery)
                }else {
                    Button(action:{
                        isSearching = true
                    }){
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            // TODO: Add search field ToolbarItem — TextField bound to searchQuery, with Image(systemName: "magnifyingglass") prefix icon.
            // Pass searchQuery down to FileListView and filter the displayed files there.

            // TODO: Add batch search ToolbarItem — Button with Image(systemName: "wand.and.stars") that sets showingBatchSearch = true.
            // Add .sheet(isPresented: $showingBatchSearch) for the batch search view (to be built).
        }
    }
}

#Preview {
    ContentView()
}
