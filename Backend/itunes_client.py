import os
import httpx
from models import iTunesTrack

class iTunesClient:

    def __init__(self):
        self.itunes_client = None

    def search_track(self, query: str) -> list[iTunesTrack]:
        if query == "":
            raise ValueError("Query must not be empty")
        search_results = []
        response = httpx.get(f'https://itunes.apple.com/search?term={query}&media=music&entity=song&limit=10&sort=recent')
        results = response.json()

        for track in results['results']:
            date = track.get("releaseDate") or ""
            if date != "":
                date = (track['releaseDate']).split("T")[0]
            mapped_dict = {
                "itunes_id": str(track['trackId']),
                "title": track['trackName'],
                "artist": track['artistName'],
                "album": track['collectionName'],
                "date": date,
                "track_number": track["trackNumber"],
                "album_artist": track['artistName'],
                "artwork_url": track['artworkUrl30'].replace("30x30bb.jpg", "3000x3000bb.jpg")
            }
            temp = iTunesTrack(**mapped_dict)
            search_results.append(temp)
        return search_results

    def get_track_metadata(self, track_id: str) -> iTunesTrack:

        track = httpx.get(f'https://itunes.apple.com/lookup?id={track_id}&media=music&entity=song').json()
        if "errorMessage" in track:
            raise ValueError("Invalid iTunes Track ID")

        date = track['results'][0].get("releaseDate") or ""
        if date != "":
            date = (track['results'][0]['releaseDate']).split("T")[0]

        mapped_dict = {
            "itunes_id": str(track['results'][0]['trackId']),
            "title": track['results'][0]['trackName'],
            "artist": track['results'][0]['artistName'],
            "album": track['results'][0]['collectionName'],
            "date": date,
            "track_number": track['results'][0]["trackNumber"],
            "album_artist": track['results'][0]['artistName'],
            "artwork_url": track['results'][0]['artworkUrl30'].replace("30x30bb.jpg", "3000x3000bb.jpg")
        }

        return iTunesTrack(**mapped_dict)

    def get_album_artwork(self, track_id: str) -> bytes:
        itunesTrack = self.get_track_metadata(track_id)
        image = httpx.get(itunesTrack.artwork_url)
        if image.status_code == 200:
            return image.content
        else:
            raise ValueError("Invalid album URL")