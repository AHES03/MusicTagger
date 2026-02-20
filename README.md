# MusicTag

A native macOS app for editing music file metadata using the Spotify API as a source of truth.

Browse your local music library, search Spotify for the correct track, and write clean metadata — title, artist, album, artwork, and more — directly to your audio files.

---

## Features

- Browse and select local music files (MP3, FLAC, AAC)
- Search Spotify for track metadata
- View and edit existing file tags
- Write metadata and embed album artwork directly to files
- Supports multiple audio formats via automatic format detection

---

## Architecture

MusicTag is split into two components:

**SwiftUI Frontend (`MT_UI/`)**
- Native macOS UI built with SwiftUI
- Handles folder browsing and file selection
- Communicates with the Python backend over local HTTP

**Python Backend (`Backend/`)**
- FastAPI server running locally
- Integrates with the Spotify Web API via `spotipy`
- Reads and writes audio file tags via `mutagen`

---

## Project Structure

```
MusicTag/
├── MT_UI/                        # Xcode project
│   └── MT_UI/                    # SwiftUI macOS app source
│       ├── MT_UIApp.swift        # App entry point
│       ├── ContentView.swift
│       ├── Views/
│       │   ├── FileListView.swift
│       │   ├── MetadataEditorView.swift
│       │   └── SpotifySearchView.swift
│       ├── Models/
│       │   ├── Track.swift
│       │   └── MusicFile.swift
│       └── Services/
│           ├── APIClient.swift
│           └── BackendLauncher.swift
└── Backend/                      # Python FastAPI server
    ├── main.py                   # API routes
    ├── spotify_client.py         # Spotify API integration
    ├── metadata.py               # Audio file tag reader/writer
    ├── models.py                 # Pydantic request/response models
    ├── requirements.txt
    └── tests/
```

---

## Getting Started

### Prerequisites

- macOS 13+
- Python 3.11+
- Xcode 15+
- A [Spotify Developer](https://developer.spotify.com/dashboard) account

### Backend Setup

```bash
cd Backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Copy the environment template and add your Spotify credentials:

```bash
cp .env.example .env
```

```
SPOTIFY_CLIENT_ID=your_client_id
SPOTIFY_CLIENT_SECRET=your_client_secret
```

Start the backend:

```bash
uvicorn main:app --reload
```

### Frontend Setup

Open `MT_UI/MT_UI.xcodeproj` in Xcode and run the app. The SwiftUI frontend will connect to the locally running Python server on startup.

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Check backend is running |
| `POST` | `/search` | Search Spotify for tracks |
| `POST` | `/read-metadata` | Read tags from a local file |
| `POST` | `/write-metadata` | Write tags to a local file |
| `POST` | `/write-artwork` | Embed album artwork into a local file |

---

## Running Tests

```bash
cd Backend
pytest
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | SwiftUI (macOS) |
| Backend | Python, FastAPI |
| Spotify Integration | spotipy |
| Audio Tag Editing | mutagen |
| Testing | pytest |
