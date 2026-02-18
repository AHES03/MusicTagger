import pytest
from spotify_client import SpotifyClient
from spotipy.exceptions import SpotifyOauthError
from models import SpotifyTrack
from unittest.mock import patch, MagicMock


class TestAuthentication:

    def test_authenticate_succeeds_with_valid_credentials(self, spotify_client):
        """Client should authenticate without raising an exception."""
        test = SpotifyClient()
        test.authenticate()
        assert test.sp_client is not None



    def test_authenticate_fails_with_missing_credentials(self):
        """Client should raise an error when env vars are missing."""
        test = SpotifyClient()
        test.client_id =""

        with pytest.raises(SpotifyOauthError) as excinfo:
            test.authenticate()
        assert "No client_id" in str(excinfo.value)




class TestSearchTrack:

    def test_search_returns_list(self, spotify_client):
        """A valid query should return a list."""
        query = "The Beatles"
        test = SpotifyClient()
        test.authenticate()
        response = test.search_track(query)
        assert isinstance(response, list)


    def test_search_result_contains_expected_fields(self, spotify_client):
        """Each result should have: spotify_id, title, artist, album, year, artwork_url."""
        query = "The Beatles"
        test = SpotifyClient()
        test.authenticate()
        response = test.search_track(query)
        assert type(response[0]) == SpotifyTrack


    def test_search_with_empty_query_raises_error(self, spotify_client):
        """An empty query string should raise a ValueError."""
        query = ""
        test = SpotifyClient()
        test.authenticate()

        with pytest.raises(ValueError) as excinfo:
            response = test.search_track(query)
        assert "Query must not be empty" in str(excinfo.value)


class TestGetTrackMetadata:

    def test_returns_dict_with_all_fields(self, spotify_client):
        """A valid track ID should return a dict with all metadata fields."""
        trackId = '3GfOAdcoc3X5GPiiXmpBjK'
        test = SpotifyClient()
        test.authenticate()
        response = test.get_track_metadata(trackId)
        assert type(response) == SpotifyTrack


    def test_invalid_track_id_raises_error(self, spotify_client):
        """An invalid track ID should raise an appropriate error."""
        trackId = 'hagyugwegqw73e32f'
        test = SpotifyClient()
        test.authenticate()
        with pytest.raises(ValueError) as excinfo:
            response = test.get_track_metadata(trackId)
        assert "Invalid Spotify Track ID" in str(excinfo.value)


class TestGetAlbumArtwork:

    def test_returns_bytes(self, spotify_client):
        """A valid track ID should return image data as bytes."""
        trackId = '3GfOAdcoc3X5GPiiXmpBjK'
        test = SpotifyClient()
        test.authenticate()
        response = test.get_album_artwork(trackId)
        assert type(response) == bytes


    def test_bad_artwork_url_raises_error(self, spotify_client):
        """An invalid track ID should raise an appropriate error."""
        trackId = '3GfOAdcoc3X5GPiiXmpBjK'  # valid track
        test = SpotifyClient()
        test.authenticate()

        mock_response = MagicMock()
        mock_response.status_code = 404  # force a bad response

        with patch('httpx.get', return_value=mock_response):
            with pytest.raises(ValueError):
                test.get_album_artwork(trackId)

