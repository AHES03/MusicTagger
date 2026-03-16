import mutagen.flac
from mutagen import File
from models import MetadataPayload
from mutagen.flac import Picture
import base64

class MetadataReader:
    """@brief Reads existing metadata tags from a local music file."""

    def __init__(self, file_path: str):
        ## @brief Loads the audio file using mutagen.
        ## @param file_path Absolute path to the local audio file.
        ## @throws ValueError if the file does not exist or format is unsupported.
        self.file_path = file_path
        # TODO: Replace mutagen.File() with music_tag.load_file() for unified format support.
        # music_tag raises an exception if the file doesn't exist or format is unsupported,
        # so keep the same try/except + None check pattern but map to music_tag's exceptions.
        try:
            self.audio = File(self.file_path)
        except:
            raise ValueError("File does not exist")
        if self.audio is None:
            raise ValueError("Unsupported file format")


    def read(self) -> MetadataPayload:
        """
        @brief Read and return all existing metadata fields from the file.
        @return A MetadataPayload containing title, artist, album, track_number, date, genre, spotify_id.
        """
        # TODO: Replace all self.audio.get(...) calls with music_tag field access:
        #   e.g. self.audio['title'].value  — works the same across FLAC, MP3, MP4, OGG.
        track_number_raw = self.audio.get('tracknumber', [None])[0]
        disc_namer_raw =  self.audio.get('discnumber', [None])[0]

        # TODO: Replace the mutagen pictures block with music_tag artwork access:
        #   self.audio['artwork'].value gives raw image bytes directly (or None if absent).
        #   Then base64-encode as before.
        pictures = self.audio.pictures
        picture =None
        image_encoded = None
        for i in pictures:
            if i.type == 3:
                picture = i.data
        if picture is not None:
            image_encoded = base64.b64encode(picture).decode('utf-8')

        # TODO: Update each key below to use music_tag field names:
        #   title, artist, album, tracknumber, year, genre, comment, albumartist,
        #   composer, discnumber, compilation, artwork — check music_tag docs for exact names.
        mapped_dict = {
            "file_path": self.file_path,
            "title": self.audio.get('title', [None])[0],
            "artist": self.audio.get('artist', [None])[0],
            "album": self.audio.get('album', [None])[0],
            "track_number": int(track_number_raw) if track_number_raw is not None else None,
            "date": self.audio.get('date', [None])[0],
            "genre": self.audio.get('genre', [None])[0],
            "spotify_id": self.audio.get('spotify_id', [None])[0],
            "comment": self.audio.get('comment', [None])[0],
            "album_artist":self.audio.get('albumartist', [None])[0],
            "composer": self.audio.get('composer', [None])[0],
            "disc_number":int(disc_namer_raw) if disc_namer_raw is not None else None,
            "is_compilation": self.audio.get('is_compilation', [None])[0],
            "artwork_data": image_encoded

        }
        return MetadataPayload(**mapped_dict)



class MetadataWriter:
    """@brief Writes metadata tags to a local music file."""

    def __init__(self, file_path: str):
        ## @brief Loads the audio file using mutagen.
        ## @param file_path Absolute path to the local audio file.
        ## @throws ValueError if the file does not exist or format is unsupported.
        self.file_path = file_path
        # TODO: Replace mutagen.File() with music_tag.load_file() — same as MetadataReader.__init__.
        try:
            self.audio = File(self.file_path)
        except:
            raise ValueError("File does not exist")
        if self.audio is None:
            raise ValueError("Unsupported file format")

    def write(self, metadata: MetadataPayload) -> None:
        """
        @brief Write the provided MetadataPayload to the file's tags.
        @param metadata A MetadataPayload containing the fields to write.
        Handles MP3 (ID3), MP4/AAC, and FLAC formats.
        """
        # TODO: Replace all self.audio['key'] = value assignments with music_tag equivalents:
        #   self.audio['title'] = metadata.title  (music_tag uses the same syntax, just different key names).
        #   Call self.audio.save() at the end as before — music_tag uses the same save() call.
        self.audio['title'] = metadata.title
        self.audio["artist"] = metadata.artist
        self.audio['album'] = metadata.album
        self.audio["tracknumber"] = str(metadata.track_number)
        self.audio["date"] = metadata.date
        if metadata.comment is not None:
            self.audio["comment"] = metadata.comment
        if metadata.album_artist is not None:
            self.audio["albumartist"] = metadata.album_artist
        if metadata.composer is not None:
            self.audio["composer"] = metadata.composer
        if metadata.disc_number is not None:
            self.audio["discnumber"] = str(metadata.disc_number)
        if metadata.is_compilation is not None:
            self.audio["compilation"] = metadata.is_compilation

        if metadata.genre is not None:
            self.audio['genre'] = metadata.genre
        if metadata.spotify_id is not None:
            self.audio['spotify_id'] = metadata.spotify_id
        self.audio.save()


    def write_artwork(self, image_bytes: bytes) -> None:
        """
        @brief Embed album artwork into the file's tags.
        @param image_bytes Raw JPEG image bytes to embed as front cover.
        @throws ValueError if the bytes are not a valid JPEG image.
        """
        if b'\xff\xd8\xff' not in image_bytes:
            raise ValueError("Invalid cover file type")

        # TODO: Replace the mutagen Picture block with music_tag artwork writing:
        #   Wrap image_bytes in a music_tag.core.ArtworkCollection or assign directly:
        #   self.audio['artwork'] = image_bytes  then self.audio.save().
        #   Remove the mutagen Picture, clear_pictures(), and add_picture() calls entirely.
        picture = Picture()
        picture.type = 3
        picture.mime = "image/jpeg"
        picture.data = image_bytes

        self.audio.clear_pictures()
        self.audio.add_picture(picture)
        self.audio.save()
