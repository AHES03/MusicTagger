// Root view. Composes the metadata editor panel and file list panel side by side.

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// NSViewRepresentable wrapper around NSTextField that calls becomeFirstResponder
/// when isFocused is true — needed because SwiftUI @FocusState is unreliable in toolbar items on macOS.
private struct FocusableTextField: NSViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var onSubmit: () -> Void
    @Binding var clearTrigger: Bool
    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = "Search ..."
        field.delegate = context.coordinator
        field.bezelStyle = .roundedBezel
        return field
    }

    func updateNSView(_ nsView: NSTextField, context _: Context) {
        // Skip stringValue assignment while the field is active — currentEditor() returns the
        // field editor (NSTextView) when typing, nil otherwise. Setting stringValue while the
        // field editor is live resets the cursor to position 0 on every keystroke.
        // clearTrigger bypasses the currentEditor() guard to force-clear the field from outside.
        if clearTrigger {
            nsView.stringValue = ""
            nsView.currentEditor()?.string = ""
            DispatchQueue.main.async { self.clearTrigger = false }
            return
        }


        // Delayed to allow the width animation (spring ~0.3s) to settle before the field editor
        // is created — otherwise the placeholder renders against a near-zero frame width.
        // Guard is inside the block so it re-evaluates at fire time, not schedule time —
        // prevents stacked makeFirstResponder calls from file-load re-renders resetting the cursor.
        if isFocused {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard nsView.currentEditor() == nil else { return }
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: FocusableTextField
        init(_ parent: FocusableTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSTextField {
                parent.text = field.stringValue
            }
        }

        func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
        func controlTextDidEndEditing(_ notification: Notification) {
            parent.onSubmit()
        }
    }
}

struct ContentView: View {
    @State private var selectedFile: MusicFile?
    @State private var files: [MusicFile] = []
    @State private var editorRefreshID = UUID()
    @State var searchQuery: String = ""
    @State var isSearching: Bool = false
    @State var showingBatchSearch: Bool = false
    @State private var clearTrigger: Bool = false
    var isBackendOnline: Bool
    var filteredFiles: [MusicFile] {
        searchQuery.isEmpty ? files : files.filter { file in
            (file.title ?? "").localizedCaseInsensitiveContains(searchQuery) || (file.album ?? "").localizedCaseInsensitiveContains(searchQuery) ||
                (file.artist ?? "").localizedCaseInsensitiveContains(searchQuery) || (file.filePath).localizedCaseInsensitiveContains(searchQuery)
        }
    }

    @Environment(\.undoManager) var undoManager

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                // Left Pane: Metadata Editor
                MetadataEditorView(file: $selectedFile, onSave: { before, after in
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
                    .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 800)
            } detail: {
                // Right Pane: File List
                if isBackendOnline{
                    FileListView(files: $files, onSelect: $selectedFile, displayedFiles: filteredFiles)
                }else{
                    FileLoadingView()
                }
            }
            .navigationTitle("")
            .toolbar {
                // MARK: Undo / Redo — always visible, unaffected by search state
                ToolbarItem(placement: .navigation) {
                    Button(action: { undoManager?.undo() }) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button(action: { undoManager?.redo() }) {
                        Image(systemName: "arrow.uturn.forward")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: isSearching ? 0 : 8) {
                        // MARK: Folder + Batch — collapse when searching
                        HStack(spacing: 8) {
                            Button(action: {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = true
                                panel.canChooseDirectories = true
                                panel.allowedContentTypes = [.audio]
                                guard panel.runModal() == .OK else { return }
                                func importURL(_ url: URL, depth: Int) {
                                    let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                                    let isAudio = ["flac", "mp3", "m4a", "aac", "wav"].contains(url.pathExtension.lowercased())
                                    if isDirectory, depth < 3 {
                                        let childUrls = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
                                        for childUrl in childUrls {
                                            importURL(childUrl, depth: depth + 1)
                                        }
                                    } else if isAudio {
                                        Task { @MainActor in
                                            do {
                                                try await files.append(APIClient.shared.readMetadata(filePath: url.path))
                                            } catch {}
                                        }
                                    }
                                }
                                for url in panel.urls {
                                    importURL(url, depth: 0)
                                }
                            }) {
                                Image(systemName: "folder.badge.plus")
                            }
                            Button(action: { showingBatchSearch = true }) {
                                Image(systemName: "wand.and.stars")
                            }
                        }
                        .frame(width: isSearching ? 0 : nil)
                        .opacity(isSearching ? 0 : 1)
                        .scaleEffect(isSearching ? 0.8 : 1)
                        .clipped()
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearching)

                        // MARK: Search — text field slides in from trailing edge
                        HStack(spacing: 4) {
                            FocusableTextField(text: $searchQuery, isFocused: isSearching, onSubmit: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isSearching = false }
                            }, clearTrigger: $clearTrigger)
                            .frame(width: isSearching ? 180 : 0)
                            .opacity(isSearching ? 1 : 0)
                            .offset(x: isSearching ? 0 : 20)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearching)

                            Button(action: {
                                if !searchQuery.isEmpty && isSearching {
                                    searchQuery = ""
                                    clearTrigger = true
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isSearching = true }
                                }
                            }) {
                                Image(systemName: (!searchQuery.isEmpty && isSearching) ? "xmark" : "magnifyingglass")
                            }
                        }
                    }
                }
            }
            StatusBarView(itemSelected: selectedFile != nil, files: $files, selectedFile: selectedFile)
        }
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
    ContentView(isBackendOnline: true)
}
