from fastapi import FastAPI, HTTPException
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
    try:
        resp = spotify.search_track(query)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    return {'Tracks': resp}


@app.post("/read-metadata",status_code=200)
def read_metadata(request: ReadMetadataRequest):
    """Read and return existing metadata from a local file."""
    path = request.file_path
    try:
        metadata_reader = MetadataReader(path)
    except ValueError as e:
        if "File does not exist" in str(e):
            raise HTTPException(status_code=404, detail=str(e))
        elif "Unsupported file format" in str(e):
            raise HTTPException(status_code=422, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail=str(e))
    metadata = metadata_reader.read()
    return {'Metadata': metadata}


@app.post("/write-metadata")
def write_metadata(payload: MetadataPayload):
    """Write metadata (and artwork) to a local file."""
    pass
