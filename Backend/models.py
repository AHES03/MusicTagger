from pydantic import BaseModel
from typing import Optional

class Track (BaseModel):
    title: str
    artist: str
    album: str
    date: str
    artwork_url: str
    track_number: int
    album_artist: str

class iTunesTrack(Track):
    """A single iTunes track search result."""
    itunes_id: str

class SpotifyTrack(Track):
    """A single Spotify track search result."""
    spotify_id: str


class MetadataPayload(BaseModel):
    """Metadata fields to be written to a local file."""
    file_path: str
    title: Optional[str] = None
    artist: Optional[str] = None
    album: Optional[str] = None
    track_number: Optional[int] = None
    date: Optional[str] = None
    genre: Optional[str] = None
    comment: Optional[str] = None
    album_artist: Optional[str] = None
    composer: Optional[str] = None
    disc_number: Optional[int] = None
    is_compilation: Optional[bool] = None
    artwork_data: Optional[str] = None
    sample_rate: Optional[int] = None
    bit_depth: Optional[int] = None
    format: Optional[str] = None


class SearchRequest(BaseModel):
    """Request body for a Spotify track search."""
    query: str


class ReadMetadataRequest(BaseModel):
    """Request body for reading metadata from a local file."""
    file_path: str


class WriteArtworkRequest(BaseModel):
    """Request body for writing artwork to a local audio_MT file."""
    file_path: str
    artwork_path: str
