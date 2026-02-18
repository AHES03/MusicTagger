# Backend TODO

## Setup
- [x] Copy `.env.example` to `.env` and fill in your Spotify credentials
- [x] Create a virtual environment and run `pip install -r requirements.txt`

---

## spotify_client.py

- [x] `__init__` — load env vars using `python-dotenv`
- [x] `authenticate` — set up `SpotifyClientCredentials` and assign the `Spotify` client instance to `self`
- [x] `search_track` — call Spotify search API, return a list of simplified track dicts
- [x] `get_track_metadata` — fetch a single track by ID, extract and return all relevant fields
- [x] `get_album_artwork` — use the artwork URL from track metadata to download and return image bytes

---

## metadata.py

- [ ] `MetadataReader.__init__` — load the file with mutagen, detect format (MP3 / MP4 / FLAC)
- [ ] `MetadataReader.read` — extract and return all tag fields as a dict
- [ ] `MetadataWriter.__init__` — load the file with mutagen, detect format
- [ ] `MetadataWriter.write` — map the metadata dict fields to the correct mutagen tag keys per format
- [ ] `MetadataWriter.write_artwork` — embed image bytes into the correct tag field per format

---

## main.py

- [ ] `health_check` — return a simple `{"status": "ok"}` response
- [ ] `search` — call `SpotifyClient.search_track`, return results as a list of `TrackResult`
- [ ] `read_metadata` — instantiate `MetadataReader` and return the result
- [ ] `write_metadata` — fetch artwork via `SpotifyClient.get_album_artwork`, then use `MetadataWriter` to write tags and artwork

---

## General
- [ ] Add error handling to all routes (invalid file path, Spotify API errors, unsupported file format)
- [ ] Test each route manually with a tool like Postman or `curl` before connecting the SwiftUI frontend
