import mutagen.flac
from mutagen import File
from models import MetadataPayload
from mutagen.flac import Picture

class MetadataReader:
    """Reads existing metadata tags from a local music file."""

    def __init__(self, file_path: str):
        # Load the file using mutagen
        self.file_path = file_path
        try:
            self.audio = File(self.file_path)
        except:
            raise ValueError("File does not exist")
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
        self.file_path = file_path
        try:
            self.audio = File(self.file_path)
        except:
            raise ValueError("File does not exist")
        if self.audio is None:
            raise ValueError("Unsupported file format")

    def write(self, metadata: MetadataPayload) -> None:
        """
        Write the provided MetadataPayload to the file's tags.
        Handles MP3 (ID3), MP4/AAC, and FLAC formats.
        """
        self.audio['title'] = metadata.title
        self.audio["artist"] = metadata.artist
        self.audio['album'] = metadata.album
        self.audio["tracknumber"] = str(metadata.track_number)
        self.audio["date"] = metadata.date
        if metadata.genre is not None:
            self.audio['genre'] = metadata.genre
        if metadata.spotify_id is not None:
            self.audio['spotify_id'] = metadata.spotify_id
        self.audio.save()


    def write_artwork(self, image_bytes: bytes) -> None:
        """
        Embed album artwork into the file's tags.
        """
        if b'\xff\xd8\xff' not in image_bytes:
            raise ValueError("Invalid cover file type")
        picture = Picture()
        picture.type = 3
        picture.mime = "image/jpeg"
        picture.data = image_bytes

        self.audio.clear_pictures()
        self.audio.add_picture(picture)
        self.audio.save()
