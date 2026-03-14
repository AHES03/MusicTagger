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
- [x] `setup()` — auto-create venv and always run `pip install -r requirements.txt` on launch

---

## Views

### ContentView.swift
- [x] `HSplitView` with `MetadataEditorView` (left) and `FileListView` (right)
- [x] Shared state — `@State files: [MusicFile]`, `@State selectedFile: MusicFile?`
- [x] Window minimum size constraint
- [x] Toolbar — Open Files button via `NSOpenPanel`
- [ ] UI polish — left panel width too narrow, fields getting cut off

### FileListView.swift
- [x] `Table` with columns: Title, Track #, Artist, Album
- [x] Single-row selection (`MusicFile.ID?`)
- [x] `.alternatingRowBackgrounds()` for striped appearance
- [x] Right-click context menu — Remove from list, Show in Finder
- [x] Wire selection changes to `onSelect` binding via `.onChange(of: selection)`
- [x] Call `APIClient.readMetadata` when selection changes, update file metadata
- [x] Empty state placeholder
- [ ] Drag-and-drop import — blocked by SwiftUI `Table` consuming drag events; requires AppKit `NSTableView` integration

### MetadataEditorView.swift
- [x] Text fields — Title, Artist, Album, Date, Track Number, Genre
- [x] Inline row — Date / Track # / Genre
- [x] Extra fields — Comment, Album Artist, Composer, Disc Number, Compilation toggle
- [x] Artwork preview area — show image or placeholder disc icon
- [x] Search Spotify button — open `SpotifySearchView` as sheet
- [x] Save button — call `writeMetadata`
- [x] Nil state — placeholder when no file is selected
- [ ] Artwork tap/drop — open file picker, call `writeArtwork`
- [ ] UI polish — inline HStack rows cramped, artwork area unstyled

### SpotifySearchView.swift
- [x] Search bar — TextField + Search button, pre-filled from file title/artist
- [x] Loading indicator — `isLoading` toggled around async call
- [x] Results list — `AsyncImage` thumbnail, title, artist, album, date
- [x] Empty/error state messages
- [x] On selection — map `Track` → `MusicFile` fields, download artwork data, dismiss sheet

---

## App
- [x] `MT_UIApp.swift` — wire up `BackendLauncher`, launch on appear, terminate on quit
- [x] Add `NSAppTransportSecurity` to `Info.plist` to allow HTTP to `127.0.0.1`
- [x] Remove App Sandbox entitlement to allow `Process()` spawning
- [x] Add `Pillow` to `requirements.txt`

---

## Backend (model updates required)
- [ ] Add `comment`, `album_artist`, `composer`, `disc_number`, `is_compilation` to `MetadataPayload`, `MetadataReader`, `MetadataWriter`
