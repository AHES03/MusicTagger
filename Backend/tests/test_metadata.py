import pytest
from pathlib import Path
from spotify_client import SpotifyClient
from metadata import MetadataReader, MetadataWriter
from models import MetadataPayload
import mutagen

_TEST_FILES = Path(__file__).parent.parent.parent / "test_files"
_FLAC = str(_TEST_FILES / "Maro - SO MUCH HAS CHANGED" / "MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac")
_FLAC_INVALID = str(_TEST_FILES / " - SO MUCH HAS CHANGED" / "MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac")


class TestMetadataReader:

    def test_read_returns_metadata_payload(self):
        """Reading a valid file should return a MetadataPayload."""
        test = MetadataReader(_FLAC)
        metadata_resp = test.read()
        print(metadata_resp)
        assert type(metadata_resp) == MetadataPayload


    def test_read_contains_expected_fields(self, sample_audio_file):
        """Result should include: title, artist, album, track_number, date, genre."""
        test = MetadataReader(_FLAC)
        metadata_resp = test.read()
        assert isinstance(metadata_resp.title, str) or metadata_resp.title is None


    def test_read_invalid_path_raises_error(self):
        """Providing a non-existent file path should raise an error."""
        with pytest.raises(ValueError) as excinfo:
            test = MetadataReader(_FLAC_INVALID)
        assert "File does not exist" in str(excinfo.value)


    def test_read_unsupported_format_raises_error(self, tmp_path):
        """Providing a non-audio_MT file should raise an appropriate error."""
        dummy = tmp_path / "dummy.docx"
        dummy.write_bytes(b"not a real document")
        with pytest.raises(ValueError) as excinfo:
            test = MetadataReader(str(dummy))
        assert "File does not exist" in str(excinfo.value)


class TestMetadataWriter:

    def test_write_updates_tags_on_file(self):
        """After writing a MetadataPayload, reading the file back should reflect the new values."""
        reader = MetadataReader(_FLAC)
        reader_payload = reader.read()
        reader_payload.title = 'Hello'
        writer = MetadataWriter(_FLAC)
        writer.write(reader_payload)
        new_reader = MetadataReader(_FLAC)
        new_reader = new_reader.read()
        print(new_reader.date)
        assert new_reader.title == "Hello"


    def test_write_invalid_path_raises_error(self):
        """Providing a non-existent file path should raise an error."""
        with pytest.raises(ValueError) as excinfo:
            test = MetadataWriter(_FLAC_INVALID)
        assert "File does not exist" in str(excinfo.value)


    def test_write_artwork_embeds_image(self, sample_audio_file):
        """After writing artwork, the file should contain embedded image bytes."""
        sp = SpotifyClient()
        test = MetadataWriter(_FLAC)
        sp.authenticate()
        pict = sp.get_album_artwork("6vvhhwl8XabfZJBq5d1iIB")
        test.write_artwork(pict)
        test_audio = mutagen.File(_FLAC)
        assert len(test_audio.pictures) > 0
        assert test_audio.pictures[0].data == pict

    def test_write_artwork_with_invalid_bytes_raises_error(self, sample_audio_file):
        """Passing non-image bytes as artwork should raise an appropriate error."""
        reader = MetadataWriter(_FLAC)
        with pytest.raises(ValueError) as excinfo:
            reader.write_artwork(b"this is not an image")
        assert "Invalid cover file type" in str(excinfo.value)
