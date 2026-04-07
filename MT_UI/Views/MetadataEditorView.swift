import SwiftUI

struct MetadataEditorView: View {
    @Binding var file: MusicFile?
    @State private var lastSavedFile: MusicFile?
    @State var showingSpotifySearch = false
    var onSave: (_ before: MusicFile, _ after: MusicFile) -> Void
    var refreshID: UUID
    
    var body: some View {
        VStack(spacing: 0) {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title and artist header
                VStack(alignment: .leading) {
                    Text("\(file?.title ?? "") - \(file?.artist ?? "")")
                        .font(Font.largeTitle.bold())
                    Text(URL(fileURLWithPath: file?.filePath ?? "").lastPathComponent)
                        .font(.subheadline)
                }
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Artwork matching field width
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.15))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Group {
                            if let data = file?.artworkData, let nsImage = NSImage(data: data) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "opticaldisc")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            }
                        }
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                                    // MARK: - Text Fields
                                    VStack(alignment: .leading) {
                                        Text("Title:").font(.body)
                                        TextField("", text: Binding(get: { file?.title ?? "" }, set: { file?.title = $0.isEmpty ? nil : $0 }))
                                    }
                                    .disabled(file == nil)
                    
                                    VStack(alignment: .leading) {
                                        Text("Artist(s):").font(.body)
                                        TextField("", text: Binding(get: { file?.artist ?? "" }, set: { file?.artist = $0.isEmpty ? nil : $0 }))
                                    }
                                    .disabled(file == nil)
                    
                                    VStack(alignment: .leading) {
                                        Text("Album:").font(.body)
                                        TextField("", text: Binding(get: { file?.album ?? "" }, set: { file?.album = $0.isEmpty ? nil : $0 }))
                                    }
                                    .disabled(file == nil)
                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Date:").font(.body)
                                            TextField("", text: Binding(get: { file?.date ?? "" }, set: { file?.date = $0.isEmpty ? nil : $0 }))
                                        }
                                        .disabled(file == nil)
                    
                                        VStack(alignment: .leading) {
                                            Text("Track No:").font(.body)
                                            TextField("", text: Binding(get: { file?.trackNumber.map { String($0) } ?? "" }, set: { file?.trackNumber = Int($0) }))
                                        }
                                        .disabled(file == nil)
                    
                                        VStack(alignment: .leading) {
                                            Text("Genre:").font(.body)
                                            TextField("", text: Binding(get: { file?.genre ?? "" }, set: { file?.genre = $0.isEmpty ? nil : $0 }))
                                        }
                                        .disabled(file == nil)
                                    }
                    
                                    VStack(alignment: .leading) {
                                        Text("Album Artist(s):").font(.body)
                                        TextField("", text: Binding(get: { file?.albumArtist ?? "" }, set: { file?.albumArtist = $0.isEmpty ? nil : $0 }))
                                    }
                                    .disabled(file == nil)
                    
                                    VStack(alignment: .leading) {
                                        Text("Composer:").font(.body)
                                        TextField("", text: Binding(get: { file?.composer ?? "" }, set: { file?.composer = $0.isEmpty ? nil : $0 }))
                                    }
                                    .disabled(file == nil)
                    
                                    VStack(alignment: .leading) {
                                        Text("Comment:").font(.body)
                                        TextField("", text: Binding(get: { file?.comment ?? "" }, set: { file?.comment = $0.isEmpty ? nil : $0 }))
                                    }
                                    .disabled(file == nil)
                    
                                    HStack(alignment: .bottom) {
                                        VStack(alignment: .leading) {
                                            Text("Disc No:").font(.body)
                                            TextField("", text: Binding(get: { file?.discNumber.map { String($0) } ?? "" }, set: { file?.discNumber = Int($0) }))
                                        }
                                        .disabled(file == nil)
                                        .frame(maxWidth: .infinity)

                                        HStack {
                                            Text("Compilation:").font(.body)
                                            Toggle("", isOn: Binding(get: { file?.isCompilation ?? false }, set: { file?.isCompilation = $0 }))
                                                .disabled(file == nil)
                                        }
                                    }
                }
                
            }
            .padding()
        }

        // Stacked Buttons — fixed at bottom
        VStack(spacing: 10) {
            Button("Save") {
                let before = lastSavedFile
                Task { @MainActor in
                    do {
                        try await APIClient.shared.writeMetadata(file: file!)
                        if file?.artworkUrl != nil {
                            try await APIClient.shared.writeArtwork(filePath: file!.filePath, artworkPath: file!.artworkUrl!)
                        }
                        onSave(before ?? file!, file!)
                        lastSavedFile = file
                    } catch {}
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Search") {
                showingSpotifySearch = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
        }
        .onAppear {
            lastSavedFile = file
        }
        .onChange(of: refreshID) {
            lastSavedFile = file
        }
        .sheet(isPresented: $showingSpotifySearch) {
            SpotifySearchView(file: $file)
        }
    }
}
