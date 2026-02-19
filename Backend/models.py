from pydantic import BaseModel
from typing import Optional


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
    title: Optional[str] = None
    artist: Optional[str] = None
    album: Optional[str] = None
    track_number: Optional[int] = None
    date: Optional[str] = None
    genre: Optional[str] = None
    spotify_id: Optional[str] = None  # Used to fetch and embed artwork


class SearchRequest(BaseModel):
    """Request body for a Spotify track search."""
    query: str


class ReadMetadataRequest(BaseModel):
    """Request body for reading metadata from a local file."""
    file_path: str
