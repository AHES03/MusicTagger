import os
import httpx


class iTunesClient:

    def __init__(self):
        self.sp_client = None

    def search_track(self, query: str) -> list[iTunesTrack]:
        pass

    def get_track_metadata(self, track_id: str) -> iTunesTrack:
        pass

    def get_album_artwork(self, track_id: str) -> bytes:
        pass