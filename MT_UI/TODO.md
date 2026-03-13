# Frontend TODO

## Models
- [x] `MusicFile.swift` — fields, `Identifiable`, `Hashable`, `Codable`, `CodingKeys`, custom `init(from:)`
- [x] `Track.swift` — fields, `Identifiable`, `Decodable`, `CodingKeys`, custom `init(from:)`

---

## Services

### APIClient.swift
- [x] Singleton (`static let shared`)
- [x] Base URL constant
- [x] `SearchResponse` wrapper struct for `/search` response
- [x] `APIError` enum — `invalidResponse(String?)`, `decodingFailed`, `networkUnavailable`
- [x] `searchTracks(query:)` — POST /search, decode `SearchResponse`, return `[Track]`
- [x] `readMetadata(filePath:)` — POST /read-metadata, decode `ReadMetadataResponse`, return `MusicFile`
- [x] `writeMetadata(file:)` — POST /write-metadata, encode `MusicFile` as body
- [x] `writeArtwork(filePath:artworkPath:)` — POST /write-artwork
- [x] `healthCheck()` — GET /health, return `Bool`

### BackendLauncher.swift
- [x] `launch()` — start uvicorn via `Process()`, poll `/health` until ready
- [x] `terminate()` — shut down the process on app quit
- [x] `@Published isOnline: Bool` — signals UI when backend is up

---

## Views

### ContentView.swift
- [ ] `HSplitView` with `MetadataEditorView` (left) and `FileListView` (right)
- [ ] Shared state — `@State files: [MusicFile]`, `@State selectedFile: MusicFile?`
- [ ] Toolbar — open files button, save button
- [ ] Window minimum size constraint

### FileListView.swift
- [ ] `Table` with columns: Filename, Path, Tag, Title, Track, Artist, Album
- [ ] Single-row selection bound to `selectedFile`
- [ ] `.alternatingRowBackgrounds()` for striped appearance
- [ ] Drag-and-drop import — filter by audio extensions, call `readMetadata` for each
- [ ] Empty state placeholder
- [ ] Right-click context menu — Remove from list, Show in Finder

### MetadataEditorView.swift
- [ ] Text fields — Title, Artist, Album, Date, Track Number, Genre
- [ ] Inline row — Year / Track / Genre
- [ ] Extra fields — Comment, Album Artist, Composer, Disc Number, Compilation toggle
- [ ] Artwork preview area — show image or placeholder disc icon
- [ ] Artwork tap/drop — open file picker, call `writeArtwork`
- [ ] Search Spotify button — open `SpotifySearchView` as sheet
- [ ] Save button — call `writeMetadata`, show success/failure feedback
- [ ] Nil state — placeholder when no file is selected

### SpotifySearchView.swift
- [ ] Search bar — TextField + trigger on Return
- [ ] Results list — `AsyncImage` thumbnail, title, artist, album, date
- [ ] Loading indicator — `ProgressView` while request is in flight
- [ ] Empty/error state messages
- [ ] On selection — map `Track` → `MusicFile` fields, call `writeArtwork`, dismiss sheet

---

## App
- [ ] `MT_UIApp.swift` — wire up `BackendLauncher`, window sizing
- [ ] Add `NSAppTransportSecurity` to `Info.plist` to allow HTTP to `127.0.0.1`
