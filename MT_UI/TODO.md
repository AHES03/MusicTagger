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
- [x] `HSplitView` with `MetadataEditorView` (left) and `FileListView` (right)
- [x] Shared state — `@State files: [MusicFile]`, `@State selectedFile: MusicFile?`
- [x] Window minimum size constraint
- [ ] Toolbar — open files button, save button

### FileListView.swift
- [x] `Table` with columns: Title, Track #, Artist, Album
- [x] Single-row selection (`MusicFile.ID?`)
- [x] `.alternatingRowBackgrounds()` for striped appearance
- [x] Right-click context menu — Remove from list, Show in Finder
- [x] Wire selection changes to `onSelect` binding via `.onChange(of: selection)`
- [x] Call `APIClient.readMetadata` when selection changes, update file metadata
- [x] Drag-and-drop import — filter by audio extensions, call `readMetadata` for each
- [x] Empty state placeholder

### MetadataEditorView.swift
- [x] Text fields — Title, Artist, Album, Date, Track Number, Genre
- [x] Inline row — Date / Track # / Genre
- [x] Extra fields — Comment, Album Artist, Composer, Disc Number, Compilation toggle
- [x] Artwork preview area — show image or placeholder disc icon
- [ ] Artwork tap/drop — open file picker, call `writeArtwork`
- [x] Search Spotify button — open `SpotifySearchView` as sheet
- [x] Save button — call `writeMetadata`
- [x] Nil state — placeholder when no file is selected

### SpotifySearchView.swift
- [x] Search bar — TextField + Search button, pre-filled from file title/artist
- [x] Loading indicator — `isLoading` toggled around async call
- [ ] Results list — `AsyncImage` thumbnail, title, artist, album, date
- [ ] Empty/error state messages
- [ ] On selection — map `Track` → `MusicFile` fields, call `writeArtwork`, dismiss sheet

---

## App
- [ ] `MT_UIApp.swift` — wire up `BackendLauncher`, window sizing
- [ ] Add `NSAppTransportSecurity` to `Info.plist` to allow HTTP to `127.0.0.1`
