from music_tag import load_file
from mutagen import File
import base64
from models import MetadataPayload


class MetadataReader:
    """@brief Reads existing metadata tags from a local music file."""

    def __init__(self, file_path: str):
        ## @brief Loads the audio_MT file using music_tag.
        ## @param file_path Absolute path to the local audio_MT file.
        ## @throws ValueError if the file does not exist or format is unsupported.
        self.file_path = file_path
        try:
            self.audio_MT = load_file(self.file_path)
            self.audio_mutagen = File(self.file_path)
        except:
            raise ValueError("File does not exist")
        if self.audio_MT is None:
            raise ValueError("Unsupported file format")


    def read(self) -> MetadataPayload:
        """
        @brief Read and return all existing metadata fields from the file.
        @return A MetadataPayload containing title, artist, album, track_number, date, genre, spotify_id.
        """
        track_number_raw = self.audio_MT['tracknumber'].first
        disc_namer_raw = self.audio_MT['discnumber'].first

        artwork = self.audio_MT['artwork']
        image_encoded = None

        if artwork.value is not None:
            image_encoded = base64.b64encode(artwork.first.data).decode('utf-8')

        mapped_dict = {
            "file_path": self.file_path,
            "title": self.audio_MT['tracktitle'].first,
            "artist": self.audio_MT['artist'].first,
            "album": self.audio_MT['album'].first,
            "track_number": int(track_number_raw) if track_number_raw is not None else None,
            "date": self.audio_mutagen.get('date', [None])[0],
            "genre": self.audio_MT['genre'].first,
            "comment": self.audio_MT['comment'].first,
            "album_artist": self.audio_MT['albumartist'].first,
            "composer": self.audio_MT['composer'].first,
            "disc_number": int(disc_namer_raw) if disc_namer_raw is not None else None,
            "is_compilation": self.audio_MT['compilation'].first,
            "artwork_data": image_encoded
        }
        return MetadataPayload(**mapped_dict)



class MetadataWriter:
    """@brief Writes metadata tags to a local music file."""

    def __init__(self, file_path: str):
        ## @brief Loads the audio_MT file using music_tag.
        ## @param file_path Absolute path to the local audio_MT file.
        ## @throws ValueError if the file does not exist or format is unsupported.
        self.file_path = file_path
        try:
            self.audio_MT = load_file(self.file_path)
        except:
            raise ValueError("File does not exist")
        if self.audio_MT is None:
            raise ValueError("Unsupported file format")

    def write(self, metadata: MetadataPayload) -> None:
        """
        @brief Write the provided MetadataPayload to the file's tags.
        @param metadata A MetadataPayload containing the fields to write.
        Handles MP3 (ID3), MP4/AAC, and FLAC formats.
        """
        self.audio_MT['tracktitle'] = metadata.title
        self.audio_MT["artist"] = metadata.artist
        self.audio_MT['album'] = metadata.album
        self.audio_MT["tracknumber"] = str(metadata.track_number)
        if metadata.comment is not None:
            self.audio_MT["comment"] = metadata.comment
        if metadata.album_artist is not None:
            self.audio_MT["albumartist"] = metadata.album_artist
        if metadata.composer is not None:
            self.audio_MT["composer"] = metadata.composer
        if metadata.disc_number is not None:
            self.audio_MT["discnumber"] = str(metadata.disc_number)
        if metadata.is_compilation is not None:
            self.audio_MT["compilation"] = metadata.is_compilation
        if metadata.genre is not None:
            self.audio_MT['genre'] = metadata.genre
        self.audio_MT.save()
        try:
            self.audio_mutagen = File(self.file_path)
            self.audio_mutagen["date"] = metadata.date
            self.audio_mutagen.save()
        except:
            raise ValueError("File does not exist")
        if self.audio_mutagen is None:
            raise ValueError("Unsupported file format")




    def write_artwork(self, image_bytes: bytes) -> None:
        """
        @brief Embed album artwork into the file's tags.
        @param image_bytes Raw JPEG image bytes to embed as front cover.
        @throws ValueError if the bytes are not a valid JPEG image.
        """
        if b'\xff\xd8\xff' not in image_bytes:
            raise ValueError("Invalid cover file type")

        self.audio_MT['artwork'] = image_bytes
        self.audio_MT.save()
