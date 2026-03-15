// Root view. Composes the metadata editor panel and file list panel side by side.

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedFile: MusicFile?
    @State private var files: [MusicFile] = []
    @State private var editorRefreshID = UUID()
    @State var searchQuery: String = ""
    @State var isSearching: Bool = false
    @State var showingBatchSearch: Bool = false
    var filteredFiles: [MusicFile] { searchQuery.isEmpty ? files : files.filter { file in
        (file.title ?? "").localizedCaseInsensitiveContains(searchQuery) || (file.album ?? "").localizedCaseInsensitiveContains(searchQuery) || (file.artist ?? "").localizedCaseInsensitiveContains(searchQuery) || (file.filePath).localizedCaseInsensitiveContains(searchQuery)
    } }
    @Environment(\.undoManager) var undoManager
    var body: some View {
        HSplitView {
            MetadataEditorView(file: $selectedFile, onSave:{ before, after in

                guard let index = files.firstIndex(where: { $0.id == after.id }) else { return }
                files[index] = after
                selectedFile = after
                MetadataUndoService.shared.registerSave(
                    before: before,
                    after: after,
                    onComplete: { restored in
                        guard let index = files.firstIndex(where: { $0.id == restored.id }) else { return }
                        files[index] = restored
                        selectedFile = restored
                        editorRefreshID = UUID()
                    },
                    undoManager: undoManager
                )
            }, refreshID: editorRefreshID)
                .frame(minWidth: 200, maxWidth: .infinity)
                .frame(maxHeight: .infinity)
            // TODO: Add displayedFiles: filteredFiles parameter to FileListView once the parameter is added to its signature.
            FileListView(files: $files, onSelect: $selectedFile, displayedFiles: filteredFiles)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minWidth: 800)
        }
        .frame(minWidth: 800, minHeight: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
        if !isSearching {
            ToolbarItem(placement: .navigation){
                Button(action:{
                    undoManager?.undo()
                }){
                    Image(systemName: "arrow.uturn.backward")
                }
                
            }
            ToolbarItem(placement: .navigation){
                Button(action:{
                    undoManager?.redo()
                }){
                    Image(systemName: "arrow.uturn.forward")
                }
                
            }
            ToolbarItem{
               
                    Button(action: {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = true
                        panel.canChooseDirectories = true
                        panel.allowedContentTypes = [.audio]
                        guard panel.runModal() == .OK else { return }
                        func importURL(_ url: URL, depth: Int) {
                            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                            let isAudio = ["flac", "mp3", "m4a", "aac", "wav"].contains(url.pathExtension.lowercased())
                            if isDirectory && depth < 2 {
                                let childUrls = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
                                for childUrl in childUrls {
                                    importURL(childUrl, depth: depth + 1)
                                }
                            } else if isAudio {
                                Task { @MainActor in
                                    do {
                                        files.append(try await APIClient.shared.readMetadata(filePath: url.path))
                                    } catch {}
                                }
                            }
                        }
                        for url in panel.urls {
                            importURL(url, depth: 0)
                        }
                    }){
                        Image(systemName: "folder.badge.plus")
                    }.padding(.horizontal,8)
            }
            ToolbarItem{
                Button(action: {
                    showingBatchSearch = true
                }) {
                    Image(systemName: "wand.and.stars")
                }.padding(.horizontal,8)
            }
        }
            ToolbarItem {
                HStack {
                    
                    TextField("Search ...", text: $searchQuery)
                        .padding(.horizontal, 8)
                        .frame(width: isSearching ? 200 : 0)
                        .clipped()
                        .onSubmit { withAnimation(.easeInOut) { isSearching = false } }
                    if !isSearching {
                        Button(action: {
                            withAnimation(.easeInOut) { isSearching.toggle() }
                        }) {
                            Image(systemName: "magnifyingglass")
                        }.padding(.horizontal, 8)
                    }
                    if isSearching {
                        Button(action: {
                            searchQuery = ""
                            withAnimation(.easeInOut) { isSearching.toggle() }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                        }.padding(.horizontal, 8)
                    }
                }
                
            }
        }
        // TODO: Add a computed var filteredFiles: [MusicFile] that returns files filtered by searchQuery
        // (match title, artist, or album case-insensitively). Return all files when searchQuery is empty.
        .sheet(isPresented: $showingBatchSearch) {
            BatchSearchView(
                files: $files,
                undoManager: undoManager,
                onApply: { before, after in
                    undoManager?.beginUndoGrouping()
                    for (oldFile, newFile) in zip(before, after) {
                        guard let idx = files.firstIndex(where: { $0.id == newFile.id }) else { continue }
                        files[idx] = newFile
                        if selectedFile?.id == newFile.id { selectedFile = newFile }
                        MetadataUndoService.shared.registerSave(
                            before: oldFile,
                            after: newFile,
                            onComplete: { restored in
                                guard let idx = files.firstIndex(where: { $0.id == restored.id }) else { return }
                                files[idx] = restored
                                if selectedFile?.id == restored.id { selectedFile = restored }
                                editorRefreshID = UUID()
                            },
                            undoManager: undoManager
                        )
                    }
                    undoManager?.endUndoGrouping()
                }
            )
        }
    }
}

#Preview {
    ContentView()
}
