import pytest
from spotify_client import SpotifyClient
from metadata import MetadataReader, MetadataWriter
from models import MetadataPayload
import mutagen


class TestMetadataReader:

    def test_read_returns_metadata_payload(self):
        """Reading a valid file should return a MetadataPayload."""
        file_path = "REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac"
        test = MetadataReader(file_path)
        metadata_resp = test.read()
        print(metadata_resp)
        assert type(metadata_resp) == MetadataPayload


    def test_read_contains_expected_fields(self, sample_audio_file):
        """Result should include: title, artist, album, track_number, date, genre."""
        file_path = "REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac"
        test = MetadataReader(file_path)
        metadata_resp = test.read()
        assert isinstance(metadata_resp.title, str) or metadata_resp.title is None


    def test_read_invalid_path_raises_error(self):
        """Providing a non-existent file path should raise an error."""
        file_path = "REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/ - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac"
        with pytest.raises(ValueError) as excinfo:
            test = MetadataReader(file_path)
        assert "File does not exist" in str(excinfo.value)


    def test_read_unsupported_format_raises_error(self):
        """Providing a non-audio file should raise an appropriate error."""
        file_path = "REDACTED_USER_PATH/Downloads/Functional.docx"
        with pytest.raises(ValueError) as excinfo:
            test = MetadataReader(file_path)
        assert "Unsupported file format" in str(excinfo.value)


class TestMetadataWriter:

    def test_write_updates_tags_on_file(self):
        """After writing a MetadataPayload, reading the file back should reflect the new values."""
        file_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac'
        reader = MetadataReader(file_path)
        reader_payload = reader.read()
        reader_payload.title = 'Hello'
        writer = MetadataWriter(file_path)
        writer.write(reader_payload)
        new_reader = MetadataReader(file_path)
        new_reader = new_reader.read()
        assert new_reader.title == "Hello"


    def test_write_invalid_path_raises_error(self):
        """Providing a non-existent file path should raise an error."""
        file_path = "REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/ - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac"
        with pytest.raises(ValueError) as excinfo:
            test = MetadataWriter(file_path)
        assert "File does not exist" in str(excinfo.value)


    def test_write_artwork_embeds_image(self, sample_audio_file):
        """After writing artwork, the file should contain embedded image bytes."""
        sp = SpotifyClient()
        file_path = "REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac"
        test = MetadataWriter(file_path)
        sp.authenticate()
        pict = sp.get_album_artwork("6vvhhwl8XabfZJBq5d1iIB")
        test.write_artwork(pict)
        test_audio =  mutagen.File(file_path)
        assert len(test_audio.pictures)>0
        assert test_audio.pictures[0].data == pict

    def test_write_artwork_with_invalid_bytes_raises_error(self, sample_audio_file):
        """Passing non-image bytes as artwork should raise an appropriate error."""
        file_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac'
        reader = MetadataWriter(file_path)
        with pytest.raises(ValueError) as excinfo:
            reader.write_artwork(b"this is not an image")
        assert "Invalid cover file type" in str(excinfo.value)
