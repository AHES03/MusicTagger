//// Shows editable fields for a selected file's metadata.
//// Left panel in the two-panel layout.
//
//import SwiftUI
//
//struct MetadataEditorView: View {
//    @Binding var file: MusicFile?
//    @State var showingSpotifySearch = false
//    // Tracks the file state as it was when last loaded or saved — used as the "before" snapshot for undo.
//    @State private var lastSavedFile: MusicFile?
//    // Passes both the before (snapshot) and after (saved) state up to ContentView for undo registration.
//    var onSave: (_ before: MusicFile, _ after: MusicFile) -> Void
//    // Changed by ContentView on undo/redo to force TextFields to re-read from the binding.
//    var refreshID: UUID
//
//    var body: some View {
//        VStack(alignment: .leading) {
//
//            VStack(alignment: .leading) {
//                // MARK: - Text Fields
//                VStack(alignment: .leading){
//                    Text("Title:").font(.body)
//                    TextField("", text: Binding(get: { file?.title ?? "" }, set: { file?.title = $0.isEmpty ? nil : $0 }))
//                }
//                .disabled(file == nil)
//
//                VStack(alignment: .leading){
//                    Text("Artist(s):").font(.body)
//                    TextField("", text: Binding(get: { file?.artist ?? "" }, set: { file?.artist = $0.isEmpty ? nil : $0 }))
//                }
//                .disabled(file == nil)
//
//                VStack(alignment: .leading){
//                    Text("Album:").font(.body)
//                    TextField("", text: Binding(get: { file?.album ?? "" }, set: { file?.album = $0.isEmpty ? nil : $0 }))
//                }
//                .disabled(file == nil)
//
//                // MARK: - Inline Row (Date / Track # / Genre)
//                HStack {
//                    VStack(alignment: .leading){
//                        Text("Date:").font(.body)
//                        TextField("", text: Binding(get: { file?.date ?? "" }, set: { file?.date = $0.isEmpty ? nil : $0 }))
//                    }
//                    .disabled(file == nil)
//                    VStack(alignment: .leading){
//                        Text("Track No:").font(.body)
//                        TextField("", text: Binding(get: { file?.trackNumber.map { String($0) } ?? "" }, set: { file?.trackNumber = Int($0) }))
//                    }
//                    .disabled(file == nil)
//                    VStack(alignment: .leading){
//                        Text("Genre:").font(.body)
//                        TextField("", text: Binding(get: { file?.genre ?? "" }, set: { file?.genre = $0.isEmpty ? nil : $0 }))
//                    }
//                    .disabled(file == nil)
//                }
//
//                // MARK: - More Text Fields
//                VStack(alignment: .leading){
//                    Text("Comment:").font(.body)
//                    TextField("", text: Binding(get: { file?.comment ?? "" }, set: { file?.comment = $0.isEmpty ? nil : $0 }))
//                }
//                .disabled(file == nil)
//
//                VStack(alignment: .leading){
//                    Text("Album Artist(s):").font(.body)
//                    TextField("", text: Binding(get: { file?.albumArtist ?? "" }, set: { file?.albumArtist = $0.isEmpty ? nil : $0 }))
//                }
//                .disabled(file == nil)
//
//                VStack(alignment: .leading){
//                    Text("Composer:").font(.body)
//                    TextField("",text: Binding(get: { file?.composer ?? "" }, set: { file?.composer = $0.isEmpty ? nil : $0 }))
//                }
//                .disabled(file == nil)
//
//                // MARK: - Disc / Compilation Row
//                HStack {
//                    VStack(alignment: .leading){
//                        Text("Disc No:").font(.body)
//                        TextField("",text: Binding(get: { file?.discNumber.map { String($0) } ?? "" }, set: { file?.discNumber = Int($0) }))
//                    }
//                    .disabled(file == nil)
//                    VStack(alignment: .leading){
//                        Text("")
//                        Toggle("Compilation", isOn: Binding(get: { file?.isCompilation ?? false }, set: { file?.isCompilation = $0 })).disabled(file == nil)
//                    }
//                }
//            }
//            .id(refreshID)
//                
//                // MARK: - Album Artwork
//                // TODO: Artwork tap/drop — open NSOpenPanel, call APIClient.writeArtwork(filePath:artworkPath:), update file?.artworkData for preview.
//                if let data = file?.artworkData, let nsImage = NSImage(data: data) {
//                    ZStack{
//                        Image(nsImage: nsImage)
//                            .resizable()
//                            .scaledToFit()
//                            .clipShape(RoundedRectangle(cornerRadius: 8))
//                    }
//                    .padding(4)
//                    .frame(maxWidth: .infinity,maxHeight: .infinity)
//                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor:
//                            .darkGray).opacity(0.3)))
//                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1.0))
//                    .aspectRatio(1, contentMode: .fit)
//
//
//                } else {
//                    ZStack{
//                        Image(systemName: "opticaldisc").font(Font.system(size: 140))
//                    }
//                    .padding(4)
//                    .frame(maxWidth: .infinity,maxHeight: .infinity)
//                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor:
//                            .darkGray).opacity(0.3)))
//                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1.0))
//                    .aspectRatio(1, contentMode: .fit)
//                    
//                }
//             
//                HStack{
//                    // MARK: - Actions
//                    Button("Search Spotify"){
//                        showingSpotifySearch = true
//                    }.disabled(file == nil)
//                    Button("Save"){
//                        // lastSavedFile is the true "before" — the state as it was when loaded or last saved.
//                        let before = lastSavedFile
//                        Task{ @MainActor in
//                            do{
//                                try await APIClient.shared.writeMetadata(file: file!)
//                                if file?.artworkUrl != nil {
//                                    try await APIClient.shared.writeArtwork(filePath: file!.filePath, artworkPath: file!.artworkUrl!)
//                                }
//                                onSave(before ?? file!, file!)
//                                // Update lastSavedFile so the next save has the correct "before".
//                                lastSavedFile = file
//                            }
//                            catch{}
//                        }
//                    }.disabled(file == nil)
//                }
//        }
//        .frame(maxWidth: .infinity,
//          maxHeight: .infinity, alignment: .topLeading)
//        .padding()
//        
//        .sheet(isPresented: $showingSpotifySearch) { SpotifySearchView(file: $file) }
//        // When a new file is selected, capture it as the baseline "before" state for undo.
//        .onChange(of: file?.id) { _, _ in lastSavedFile = file }
//        // When undo/redo fires, refreshID changes — reset lastSavedFile to the restored state.
//        .onChange(of: refreshID) { _, _ in lastSavedFile = file }
//
//    }
//}
