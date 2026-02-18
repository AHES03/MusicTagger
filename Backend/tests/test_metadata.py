import pytest
from metadata import MetadataReader, MetadataWriter


class TestMetadataReader:

    def test_read_returns_dict(self, sample_audio_file):
        """Reading a valid file should return a dict."""
        pass

    def test_read_contains_expected_fields(self, sample_audio_file):
        """Result should include: title, artist, album, track_number, date, genre."""
        pass

    def test_read_invalid_path_raises_error(self):
        """Providing a non-existent file path should raise an error."""
        pass

    def test_read_unsupported_format_raises_error(self):
        """Providing a non-audio file should raise an appropriate error."""
        pass


class TestMetadataWriter:

    def test_write_updates_tags_on_file(self, sample_audio_file):
        """After writing, reading the file back should reflect the new values."""
        pass

    def test_write_invalid_path_raises_error(self):
        """Providing a non-existent file path should raise an error."""
        pass

    def test_write_artwork_embeds_image(self, sample_audio_file):
        """After writing artwork, the file should contain embedded image bytes."""
        pass

    def test_write_artwork_with_invalid_bytes_raises_error(self, sample_audio_file):
        """Passing non-image bytes as artwork should raise an appropriate error."""
        pass
