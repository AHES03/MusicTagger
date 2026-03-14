// Shows editable fields for a selected file's metadata.
// Left panel in the two-panel layout. Matches the form in Example.png.
// Includes a "Search Spotify" button to auto-fill from API results.

import SwiftUI

struct MetadataEditorView: View {
    @Binding var file: MusicFile?
    @State var showingSpotifySearch = false
    var onSave: (MusicFile) -> Void
    
    var body: some View {
        Form {
            if file != nil {
                // MARK: - Text Fields
                TextField(
                    "Title",
                    text: Binding(get: { file?.title ?? "" }, set: { file?.title = $0.isEmpty ? nil : $0 })
                )
                TextField(
                    "Artist",
                    text: Binding(get: { file?.artist ?? "" }, set: { file?.artist = $0.isEmpty ? nil : $0 })
                )
                TextField(
                    "Album",
                    text: Binding(get: { file?.album ?? "" }, set: { file?.album = $0.isEmpty ? nil : $0 })
                )
                
                // MARK: - Inline Row (Date / Track # / Genre)
                // TODO: UI polish — HStack rows cramped at narrow panel width; consider stacking vertically or increasing panel min width.
                HStack {
                    TextField(
                        "Date",
                        text: Binding(get: { file?.date ?? "" }, set: { file?.date = $0.isEmpty ? nil : $0 })
                    )
                    TextField(
                        "Track No:",
                        text: Binding(get: { file?.trackNumber.map { String($0) } ?? "" }, set: { file?.trackNumber = Int($0) })
                    )
                    TextField(
                        "Genre",
                        text: Binding(get: { file?.genre ?? "" }, set: { file?.genre = $0.isEmpty ? nil : $0 })
                    )
                }
                
                // MARK: - More Text Fields
                TextField(
                    "Comment",
                    text: Binding(get: { file?.comment ?? "" }, set: { file?.comment = $0.isEmpty ? nil : $0 })
                )
                TextField(
                    "Album Artist",
                    text: Binding(get: { file?.albumArtist ?? "" }, set: { file?.albumArtist = $0.isEmpty ? nil : $0 })
                )
                TextField(
                    "Composer",
                    text: Binding(get: { file?.composer ?? "" }, set: { file?.composer = $0.isEmpty ? nil : $0 })
                )
                
                // MARK: - Disc / Compilation Row
                HStack {
                    TextField(
                        "Disc No:",
                        text: Binding(get: { file?.discNumber.map { String($0) } ?? "" }, set: { file?.discNumber = Int($0) })
                    )
                    Toggle("Compilation", isOn: Binding(get: { file?.isCompilation ?? false }, set: { file?.isCompilation = $0 }))
                }
                
                // MARK: - Album Artwork
                // Shows artwork from file?.artworkData, or a placeholder disc icon.
                // TODO: Artwork tap/drop — open NSOpenPanel, call APIClient.writeArtwork(filePath:artworkPath:), update file?.artworkData for preview.
                // TODO: UI polish — artwork area unstyled; add fixed frame, corner radius, and border.
                if let data = file?.artworkData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame (width: 200, height: 200)
                } else {
                    Image(systemName: "opticaldisc")
                }
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
                
            } else {
                Text("No file selected")
            }
        }
        .sheet(isPresented: $showingSpotifySearch) { SpotifySearchView(file: $file) }
        .fixedSize(horizontal: true, vertical: false)

    }
}
