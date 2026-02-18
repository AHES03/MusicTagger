from pydantic import BaseModel


class SpotifyTrack(BaseModel):
    """A single Spotify track search result."""
    spotify_id: str
    title: str
    artist: str
    album: str
    date: str
    artwork_url: str


class MetadataPayload(BaseModel):
    """Metadata fields to be written to a local file."""
    file_path: str
    title: str
    artist: str
    album: str
    track_number: int
    year: str
    genre: str
    spotify_id: str  # Used to fetch and embed artwork


class SearchRequest(BaseModel):
    """Request body for a Spotify track search."""
    query: str


class ReadMetadataRequest(BaseModel):
    """Request body for reading metadata from a local file."""
    file_path: str
