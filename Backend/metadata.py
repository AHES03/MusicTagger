from mutagen import File
class MetadataReader:
    """Reads existing metadata tags from a local music file."""

    def __init__(self, file_path: str):
        # Load the file using mutagen
        self.audio = File(file_path)


    def read(self) -> dict:
        """
        Read and return all existing metadata fields from the file.
        Fields: title, artist, album, track_number, year, genre, artwork.
        """

        pass


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
