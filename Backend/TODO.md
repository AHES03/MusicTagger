# Backend TODO

## Setup
- [x] Copy `.env.example` to `.env` and fill in your Spotify credentials
- [x] Create a virtual environment and run `pip install -r requirements.txt`

---

## spotify_client.py
- [x] `__init__` — load env vars using `python-dotenv`
- [x] `authenticate` — set up `SpotifyClientCredentials` and assign the `Spotify` client instance
- [x] `search_track` — call Spotify search API, return a list of `SpotifyTrack`
- [x] `get_track_metadata` — fetch a single track by ID, return a `SpotifyTrack`
- [x] `get_album_artwork` — download and return image bytes from the artwork URL

---

## metadata.py
- [x] `MetadataReader.__init__` — load the file with mutagen, raise on missing/unsupported
- [x] `MetadataReader.read` — extract and return all tag fields as a `MetadataPayload`
- [x] `MetadataWriter.__init__` — load the file with mutagen, raise on missing/unsupported
- [x] `MetadataWriter.write` — write `MetadataPayload` fields to the correct mutagen tag keys
- [x] `MetadataWriter.write_artwork` — validate JPEG bytes and embed as front cover picture

---

## main.py
- [x] `GET /health` — return `{"Health": "ok"}`
- [x] `POST /search` — call `SpotifyClient.search_track`, return `{"Tracks": [...]}`
- [x] `POST /read-metadata` — instantiate `MetadataReader`, return `{"Metadata": ...}`
- [x] `POST /write-metadata` — instantiate `MetadataWriter`, write `MetadataPayload` to file
- [x] `POST /write-artwork` — fetch or read image, resize to 500×500 with PIL, embed via `MetadataWriter`

---

## tests
- [x] `test_spotify_client.py` — authentication, search, get metadata, get artwork
- [x] `test_metadata.py` — read, write tags, write artwork, error cases
- [x] `test_main.py` — all 5 routes, valid and invalid inputs

---

## Cleanup
- [ ] Remove stray `print()` statements
- [ ] Remove unused import `from idlelib.searchengine import search_reverse` in `main.py`
- [ ] Fix `test_write_artwork_embeds_image` — direct call bypasses PIL resize, may hit FLAC block limit
- [ ] Replace hardcoded absolute path to `Functional.docx` in `test_metadata.py` with a relative path to a file in `test_files/`
