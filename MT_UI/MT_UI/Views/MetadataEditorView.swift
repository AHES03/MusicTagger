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
            
                // MARK: - Text Fields
                // TODO: Replace each LabeledContent below with a VStack(alignment: .leading) { Text("Label").font(.caption) ; TextField(...) }
                // This places the label above the field instead of inline to the left.

                LabeledContent("Title") { TextField("", text: Binding(get: { file?.title ?? "" }, set: { file?.title = $0.isEmpty ? nil : $0 })) }.disabled(file == nil)

                LabeledContent("Artist") { TextField("", text: Binding(get: { file?.artist ?? "" }, set: { file?.artist = $0.isEmpty ? nil : $0 })) }.disabled(file == nil)

                LabeledContent("Album") { TextField("", text: Binding(get: { file?.album ?? "" }, set: { file?.album = $0.isEmpty ? nil : $0 })) }.disabled(file == nil)

                // MARK: - Inline Row (Date / Track # / Genre)
                LabeledContent("Date") { TextField("", text: Binding(get: { file?.date ?? "" }, set: { file?.date = $0.isEmpty ? nil : $0 })) }.disabled(file == nil)
                HStack {
                    // TODO: These two can stay side-by-side in the HStack, just convert each to VStack(alignment: .leading) label-above-field style.
                    LabeledContent("Track No:") { TextField("", text: Binding(get: { file?.trackNumber.map { String($0) } ?? "" }, set: { file?.trackNumber = Int($0) })) }.disabled(file == nil)

                    LabeledContent("Genre") { TextField("", text: Binding(get: { file?.genre ?? "" }, set: { file?.genre = $0.isEmpty ? nil : $0 })) }.disabled(file == nil)
                }

                // MARK: - More Text Fields
                LabeledContent("Comment") { TextField("", text: Binding(get: { file?.comment ?? "" }, set: { file?.comment = $0.isEmpty ? nil : $0 }))}.disabled(file == nil)

                LabeledContent("Album Artist") { TextField("", text: Binding(get: { file?.albumArtist ?? "" }, set: { file?.albumArtist = $0.isEmpty ? nil : $0 })) }.disabled(file == nil)

                LabeledContent("Composer") { TextField("",text: Binding(get: { file?.composer ?? "" }, set: { file?.composer = $0.isEmpty ? nil : $0 })) }.disabled(file == nil)

                // MARK: - Disc / Compilation Row
                HStack {
                    // TODO: Disc No: convert to VStack label-above-field. Toggle can stay as-is.
                    LabeledContent("Disc No:") { TextField("",text: Binding(get: { file?.discNumber.map { String($0) } ?? "" }, set: { file?.discNumber = Int($0) })) }.disabled(file == nil)
                    Toggle("Compilation", isOn: Binding(get: { file?.isCompilation ?? false }, set: { file?.isCompilation = $0 })).disabled(file == nil)
                }
                
                // MARK: - Album Artwork
                // TODO: Artwork tap/drop — open NSOpenPanel, call APIClient.writeArtwork(filePath:artworkPath:), update file?.artworkData for preview.
                if let data = file?.artworkData, let nsImage = NSImage(data: data) {
                    ZStack{
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(4)
                    .frame(maxWidth: .infinity,maxHeight: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor:
                            .darkGray).opacity(0.3)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1.0))
                    .aspectRatio(1, contentMode: .fit)


                } else {
                    ZStack{
                        Image(systemName: "opticaldisc").font(Font.system(size: 140))
                    }
                    .padding(4)
                    .frame(maxWidth: .infinity,maxHeight: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor:
                            .darkGray).opacity(0.3)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1.0))
                    .aspectRatio(1, contentMode: .fit)
                    
                }
             
                HStack{
                    // MARK: - Actions
                    Button("Search Spotify"){
                        showingSpotifySearch = true
                    }.disabled(file == nil)
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
                    }.disabled(file == nil)
                }
        }
        .frame(maxWidth: .infinity,
          maxHeight: .infinity, alignment: .topLeading)
        .padding()
        
        .sheet(isPresented: $showingSpotifySearch) { SpotifySearchView(file: $file) }

    }
}
