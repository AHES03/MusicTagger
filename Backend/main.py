from fastapi import FastAPI
from spotify_client import SpotifyClient
from metadata import MetadataReader, MetadataWriter
from models import SearchRequest, MetadataPayload, ReadMetadataRequest

app = FastAPI()
spotify = SpotifyClient()
spotify.authenticate()


@app.get("/health",status_code=200)
def health_check():
    """Confirm the backend is running."""
    resp = {"Health":"ok"}
    return resp


@app.post("/search",status_code=200)
def search(request: SearchRequest):
    """Search Spotify for tracks. Returns a list of SpotifyTrack."""
    query = request.query
    resp = spotify.search_track(query)
    return {'Tracks': resp}


@app.post("/read-metadata")
def read_metadata(request: ReadMetadataRequest):
    """Read and return existing metadata from a local file."""
    pass


@app.post("/write-metadata")
def write_metadata(payload: MetadataPayload):
    """Write metadata (and artwork) to a local file."""
    pass
