import os
import httpx
import spotipy
from models import SpotifyTrack
from dotenv import load_dotenv
from spotipy.oauth2 import SpotifyClientCredentials


class SpotifyClient:
    """@brief Handles all communication with the Spotify Web API."""

    def __init__(self):
        ## @brief Initialises the client by loading credentials from .env.
        load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))
        self.client_id = os.getenv('SPOTIFY_CLIENT_ID')
        self.client_secret = os.getenv('SPOTIFY_CLIENT_SECRET')
        self.sp_client =None

    def authenticate(self) -> None:
        """
        @brief Authenticate with the Spotify API using client credentials from .env.
        Sets up the spotipy client instance for use by other methods.
        @throws SpotifyOauthError if credentials are missing or invalid.
        """
        auth_manager = SpotifyClientCredentials(client_id=self.client_id, client_secret=self.client_secret)
        self.sp_client = spotipy.Spotify(auth_manager=auth_manager)



    def search_track(self, query: str) -> list[SpotifyTrack]:
        """
        @brief Search Spotify for tracks matching the query string.
        @param query The search string to send to Spotify.
        @return A list of SpotifyTrack objects.
        @throws ValueError if query is empty.
        """
        if not query:
            raise ValueError("Query must not be empty")
        search_results = list()
        results = self.sp_client.search(query)
        for track in results['tracks']['items']:
            mapped_dict = {
                "spotify_id":track['id'] ,
                "title": track['name'],
                "artist": (", ".join(artist["name"] for artist in track["artists"])),
                "album": track['album']['name'],
                "date": track['album']['release_date'],
                "artwork_url": track['album']['images'][0]['url']
            }
            temp = SpotifyTrack(**mapped_dict)
            search_results.append(temp)

        return search_results

    def get_track_metadata(self, track_id: str) -> SpotifyTrack:
        """
        @brief Fetch full metadata for a single track by its Spotify ID.
        @param track_id The Spotify track ID.
        @return A SpotifyTrack with title, artist, album, date, and artwork URL.
        @throws ValueError if the track ID is invalid.
        """

        try:
            track = self.sp_client.track(track_id)
        except spotipy.exceptions.SpotifyException:
            raise ValueError("Invalid Spotify Track ID")

        mapped_dict = {
            "spotify_id": track['id'],
            "title": track['name'],
            "artist": (", ".join(artist["name"] for artist in track["artists"])),
            "album": track['album']['name'],
            "date": track['album']['release_date'],
            "artwork_url": track['album']['images'][0]['url']
        }
        return SpotifyTrack(**mapped_dict)


    def get_album_artwork(self, track_id: str) -> bytes:
        """
        @brief Download and return the album artwork image as bytes.
        @param track_id The Spotify track ID to fetch artwork for.
        @return Raw image bytes of the album artwork.
        @throws ValueError if the track ID is invalid or artwork URL is unreachable.
        """
        spTrack = self.get_track_metadata(track_id)
        image = httpx.get(spTrack.artwork_url)
        if image.status_code ==200:
            return image.content
        else:
            raise ValueError("Invalid album URL")

