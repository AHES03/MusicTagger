import pytest
from itunes_client import iTunesClient
from models import iTunesTrack
from unittest.mock import patch, MagicMock


class TestAuthentication:

    def test_authenticate_succeeds_with_valid_credentials(self):
        """Client should authenticate without raising an exception."""
        test = iTunesClient()
        assert test.itunes_client is not None

class TestSearchTrack:

    def test_search_returns_list(self):
        """A valid query should return a list."""
        query = "The Beatles"
        test = iTunesClient()
        response = test.search_track(query)
        assert isinstance(response, list)


    def test_search_result_contains_expected_fields(self):
        """Each result should have: iTunes_id, title, artist, album, date, artwork_url."""
        query = "The Beatles"
        test = iTunesClient()
        response = test.search_track(query)
        assert type(response[0]) == iTunesTrack


    def test_search_with_empty_query_raises_error(self):
        """An empty query string should raise a ValueError."""
        query = ""
        test = iTunesClient()

        with pytest.raises(ValueError) as excinfo:
            response = test.search_track(query)
        assert "Query must not be empty" in str(excinfo.value)


class TestGetTrackMetadata:

    def test_returns_dict_with_all_fields(self):
        """A valid track ID should return a iTunesTrack."""
        trackId = '3GfOAdcoc3X5GPiiXmpBjK'
        test = iTunesClient()
        response = test.get_track_metadata(trackId)
        assert type(response) == iTunesTrack


    def test_invalid_track_id_raises_error(self):
        """An invalid track ID should raise an appropriate error."""
        trackId = 'hagyugwegqw73e32f'
        test = iTunesClient()
        with pytest.raises(ValueError) as excinfo:
            response = test.get_track_metadata(trackId)
        assert "Invalid iTunes Track ID" in str(excinfo.value)


class TestGetAlbumArtwork:

    def test_returns_bytes(self):
        """A valid track ID should return image data as bytes."""
        trackId = '3GfOAdcoc3X5GPiiXmpBjK'
        test = iTunesClient()
        response = test.get_album_artwork(trackId)
        assert type(response) == bytes


    def test_bad_artwork_url_raises_error(self):
        """An invalid track ID should raise an appropriate error."""
        trackId = '3GfOAdcoc3X5GPiiXmpBjK'  # valid track
        test = iTunesClient()

        mock_response = MagicMock()
        mock_response.status_code = 404  # force a bad response

        with patch('httpx.get', return_value=mock_response):
            with pytest.raises(ValueError):
                test.get_album_artwork(trackId)

