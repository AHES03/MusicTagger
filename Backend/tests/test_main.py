import pytest
from pathlib import Path

_TEST_FILES = Path(__file__).parent.parent.parent / "test_files"
_FLAC = str(_TEST_FILES / "Maro - SO MUCH HAS CHANGED" / "MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac")
_FLAC_INVALID = str(_TEST_FILES / " - SO MUCH HAS CHANGED" / "MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac")
_JPG = str(_TEST_FILES / "196873704166.jpg")
_JPG_MISSING = str(_TEST_FILES / "gue.jpg")
_FLAC_AS_IMG = str(_TEST_FILES / "Maro - SO MUCH HAS CHANGED" / "MARO - SO MUCH HAS CHANGED - 01-03 KISS ME.flac")


class TestHealthCheck:

    def test_health_returns_200(self, api_client):
        """GET /health should return a 200 status code."""
        response = api_client.get("/health")
        assert response.status_code == 200


    def test_health_returns_ok_status(self, api_client):
        """GET /health response body should indicate the server is running."""
        response = api_client.get("/health")
        assert response.json()['Health'] == 'ok'


class TestReadMetadataRoute:

    def test_read_returns_200_with_valid_file(self, api_client):
        """POST /read-metadata with a valid file path should return 200."""
        response = api_client.post("/read-metadata", json={"file_path": _FLAC})
        assert response.status_code == 200

    def test_read_returns_422_with_missing_body(self, api_client):
        """POST /read-metadata with no body should return 422."""
        response = api_client.post("/read-metadata")
        assert response.status_code == 422

    def test_read_returns_error_for_invalid_path(self, api_client):
        """POST /read-metadata with a bad file path should return an error response."""
        response = api_client.post("/read-metadata", json={"file_path": _FLAC_INVALID})
        assert response.status_code == 404


class TestSearchRoute:

    def test_search_returns_200_with_valid_query(self, api_client):
        """POST /search with a valid query should return 200."""
        response = api_client.post("/search", json={"query": "The Beatles"})
        assert response.status_code == 200


    def test_search_returns_list_of_tracks(self, api_client):
        """Response body should be a list of track objects."""
        response = api_client.post("/search", json={"query": "The Beatles"})
        assert response.status_code == 200
        assert isinstance(response.json()['Tracks'], list)


    def test_search_returns_422_with_missing_query(self, api_client):
        """POST /search with no body should return 422."""
        response = api_client.post("/search")
        assert response.status_code == 422


class TestWriteMetadataRoute:

    def test_write_returns_200_with_valid_payload(self, api_client):
        """POST /write-metadata with a full valid payload should return 200."""
        metadata_file = api_client.post("/read-metadata", json={"file_path": _FLAC})
        MT = metadata_file.json()['Metadata']
        MT['title'] = "Hello"
        metadata_file = api_client.post("/write-metadata", json=MT)
        assert metadata_file.status_code == 200

    def test_write_returns_422_with_missing_body(self, api_client):
        """POST /write-metadata with no body should return 422."""
        metadata_file = api_client.post("/write-metadata")
        assert metadata_file.status_code == 422


    def test_write_returns_error_for_invalid_path(self, api_client):
        """POST /write-metadata with a bad file path should return 404."""
        metadata_file = api_client.post("/read-metadata", json={"file_path": _FLAC})
        MT = metadata_file.json()['Metadata']
        MT['file_path'] = ""
        metadata_file = api_client.post("/write-metadata", json=MT)
        assert metadata_file.status_code == 404


class TestWriteArtworkRoute:

    def test_write_artwork_returns_200_with_valid_payload(self, api_client):
        """POST /write-artwork with valid file and artwork paths should return 200."""
        metadata_file = api_client.post("/write-artwork", json={"file_path": _FLAC, "artwork_path": _JPG})
        assert metadata_file.status_code == 200


    def test_write_artwork_returns_422_with_missing_body(self, api_client):
        """POST /write-artwork with no body should return 422."""
        metadata_file = api_client.post("/write-artwork")
        assert metadata_file.status_code == 422

    def test_write_artwork_returns_error_for_invalid_audio_path(self, api_client):
        """POST /write-artwork with a bad audio_MT file path should return 404."""
        metadata_file = api_client.post("/write-artwork", json={"file_path": _FLAC_INVALID, "artwork_path": _JPG})
        assert metadata_file.status_code == 404

    def test_write_artwork_returns_error_for_invalid_artwork_path(self, api_client):
        """POST /write-artwork with a bad artwork path should return 404."""
        metadata_file = api_client.post("/write-artwork", json={"file_path": _FLAC, "artwork_path": _JPG_MISSING})
        assert metadata_file.status_code == 404

    def test_write_artwork_returns_error_for_invalid_image_format(self, api_client):
        """POST /write-artwork with a non-image file as artwork should return 422."""
        metadata_file = api_client.post("/write-artwork", json={"file_path": _FLAC, "artwork_path": _FLAC_AS_IMG})
        assert metadata_file.status_code == 422
