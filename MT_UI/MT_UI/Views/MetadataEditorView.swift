// Shows editable fields for a selected file's metadata.
// Left panel in the two-panel layout. Matches the form in Example.png.
// Includes a "Search Spotify" button to auto-fill from API results.

import SwiftUI

struct MetadataEditorView: View {
    @Binding var file: MusicFile?
    @State var showingSpotifySearch = false
    var onSave: (MusicFile) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            if file != nil {
                // MARK: - Text Fields
                
                LabeledContent("Title") { TextField("", text: Binding(get: { file?.title ?? "" }, set: { file?.title = $0.isEmpty ? nil : $0 })) }
                
                LabeledContent("Artist") { TextField("", text: Binding(get: { file?.artist ?? "" }, set: { file?.artist = $0.isEmpty ? nil : $0 })) }
                
                LabeledContent("Album") { TextField("", text: Binding(get: { file?.album ?? "" }, set: { file?.album = $0.isEmpty ? nil : $0 })) }
                
                // MARK: - Inline Row (Date / Track # / Genre)
                LabeledContent("Date") { TextField("", text: Binding(get: { file?.date ?? "" }, set: { file?.date = $0.isEmpty ? nil : $0 })) }
                HStack {
                    LabeledContent("Track No:") { TextField("", text: Binding(get: { file?.trackNumber.map { String($0) } ?? "" }, set: { file?.trackNumber = Int($0) })) }

                    LabeledContent("Genre") { TextField("", text: Binding(get: { file?.genre ?? "" }, set: { file?.genre = $0.isEmpty ? nil : $0 })) }
                }
                
                // MARK: - More Text Fields
                LabeledContent("Comment") { TextField("", text: Binding(get: { file?.comment ?? "" }, set: { file?.comment = $0.isEmpty ? nil : $0 }))}

                LabeledContent("Album Artist") { TextField("", text: Binding(get: { file?.albumArtist ?? "" }, set: { file?.albumArtist = $0.isEmpty ? nil : $0 })) }

                LabeledContent("Composer") { TextField("",text: Binding(get: { file?.composer ?? "" }, set: { file?.composer = $0.isEmpty ? nil : $0 })) }
                
                // MARK: - Disc / Compilation Row
                HStack {
                    LabeledContent("Disc No:") { TextField("",text: Binding(get: { file?.discNumber.map { String($0) } ?? "" }, set: { file?.discNumber = Int($0) })) }
                    Toggle("Compilation", isOn: Binding(get: { file?.isCompilation ?? false }, set: { file?.isCompilation = $0 }))
                }
                
                // MARK: - Album Artwork
                // Shows artwork from file?.artworkData, or a placeholder disc icon.
                // TODO: Artwork tap/drop — open NSOpenPanel, call APIClient.writeArtwork(filePath:artworkPath:), update file?.artworkData for preview.
                if let data = file?.artworkData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity,maxHeight: .infinity)

                } else {
                    Image(systemName: "opticaldisc")
                }
                Spacer()
                HStack{
                    // MARK: - Actions
                    Button("Search Spotify"){
                        showingSpotifySearch = true
                    }
                    Button("Save"){
                        Task{
                            do{
                                try await APIClient.shared.writeMetadata(file: file!)
                                if file?.artworkUrl != nil {
                                    try await APIClient.shared.writeArtwork(filePath: file!.filePath, artworkPath: file!.artworkUrl!)
                                }
                                onSave(file!)
                            }
                            catch{
                                
                            }
                        }
                    }
                }
            } else {
                Text("No file selected")
            }

            
        }
        .frame(maxWidth: .infinity,
          maxHeight: .infinity, alignment: .topLeading)
        .padding()
        
        .sheet(isPresented: $showingSpotifySearch) { SpotifySearchView(file: $file) }

    }
}
