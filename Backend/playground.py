import os
import spotipy
from dotenv import load_dotenv
from spotipy.oauth2 import SpotifyClientCredentials

load_dotenv('.env')
client_id = os.getenv('SPOTIFY_CLIENT_ID')
client_secret = os.getenv('SPOTIFY_CLIENT_SECRET')
redirect_uri = os.getenv('SPOTIFY_REDIRECT_URI')
auth_manager = SpotifyClientCredentials(client_id=client_id, client_secret=client_secret)
sp_client = spotipy.Spotify(auth_manager=auth_manager)
result = sp_client.track('hagyugwegqw73e32f')
print(result)