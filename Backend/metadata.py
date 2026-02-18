from mutagen import File
from models import MetadataPayload

class MetadataReader:
    """Reads existing metadata tags from a local music file."""

    def __init__(self, file_path: str):
        # Load the file using mutagen
        self.file_path =file_path
        self.audio = File(file_path)
        if self.audio is None:
            raise ValueError("Unsupported file format")


    def read(self) -> MetadataPayload:
        """
        Read and return all existing metadata fields from the file.
        Fields: title, artist, album, track_number, date, genre, artwork.
        """
        track_number_raw = self.audio.get('tracknumber', [None])[0]
        mapped_dict = {
            "file_path": self.file_path,
            "title": self.audio.get('title', [None])[0],
            "artist": self.audio.get('artist', [None])[0],
            "album": self.audio.get('album', [None])[0],
            "track_number": int(track_number_raw) if track_number_raw is not None else None,
            "date": self.audio.get('date', [None])[0],
            "genre": self.audio.get('genre', [None])[0],
            "spotify_id": self.audio.get('spotify_id', [None])[0]
        }
        return MetadataPayload(**mapped_dict)



class MetadataWriter:
    """Writes metadata tags to a local music file."""

    def __init__(self, file_path: str):
        # Load the file using mutagen
        pass

    def write(self, metadata: dict) -> None:
        """
        Write the provided metadata dict to the file's tags.
        Handles MP3 (ID3), MP4/AAC, and FLAC formats.
        """
        pass

    def write_artwork(self, image_bytes: bytes) -> None:
        """
        Embed album artwork into the file's tags.
        """
        pass
