import pytest


class TestHealthCheck:

    def test_health_returns_200(self, api_client):
        """GET /health should return a 200 status code."""
        response = api_client.get("/health")
        assert response.status_code == 200


    def test_health_returns_ok_status(self, api_client):
        """GET /health response body should indicate the server is running."""
        response = api_client.get("/health")
        assert response.json()['Health'] == 'ok'


class TestSearchRoute:

    def test_search_returns_200_with_valid_query(self, api_client):
        """POST /search with a valid query should return 200."""
        query = "The Beatles"
        response = api_client.post("/search", json={"query": query})
        assert response.status_code == 200


    def test_search_returns_list_of_tracks(self, api_client):
        """Response body should be a list of track objects."""
        query = "The Beatles"
        response = api_client.post("/search", json={"query": query})
        assert response.status_code == 200
        assert isinstance(response.json()['Tracks'], list)


    def test_search_returns_422_with_missing_query(self, api_client):
        """POST /search with no body should return 422."""
        response = api_client.post("/search")
        assert response.status_code == 422



class TestReadMetadataRoute:

    def test_read_returns_200_with_valid_file(self, api_client):
        """POST /read-metadata with a valid file path should return 200."""
        file_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac'
        response = api_client.post("/read-metadata", json={"file_path": file_path})
        assert response.status_code == 200

    def test_read_returns_422_with_missing_body(self, api_client):
        """POST /read-metadata with no body should return 422."""
        response = api_client.post("/read-metadata")
        assert response.status_code == 422

    def test_read_returns_error_for_invalid_path(self, api_client):
        """POST /read-metadata with a bad file path should return an error response."""
        file_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/ - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac'
        response = api_client.post("/read-metadata", json={"file_path": file_path})
        assert response.status_code == 404


class TestWriteMetadataRoute:

    def test_write_returns_200_with_valid_payload(self, api_client):
        """POST /write-metadata with a full valid payload should return 200."""
        file_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac'
        metadata_file = api_client.post("/read-metadata", json={"file_path": file_path})
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
        file_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac'
        metadata_file = api_client.post("/read-metadata", json={"file_path": file_path})
        MT = metadata_file.json()['Metadata']
        MT['file_path'] = ""
        metadata_file = api_client.post("/write-metadata", json=MT)
        assert metadata_file.status_code == 404


class TestWriteArtworkRoute:

    def test_write_artwork_returns_200_with_valid_payload(self, api_client):
        """POST /write-artwork with valid file and artwork paths should return 200."""
        file_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac'
        img_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/196873704166.jpg'
        metadata_file = api_client.post("/write-artwork", json={"file_path": file_path,"artwork_path":img_path})

        assert metadata_file.status_code == 200


    def test_write_artwork_returns_422_with_missing_body(self, api_client):
        """POST /write-artwork with no body should return 422."""
        metadata_file = api_client.post("/write-metadata")
        assert metadata_file.status_code == 422

    def test_write_artwork_returns_error_for_invalid_audio_path(self, api_client):
        """POST /write-artwork with a bad audio file path should return 404."""
        file_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/ - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac'
        img_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/196873704166.jpg'
        metadata_file = api_client.post("/write-artwork", json={"file_path": file_path, "artwork_path": img_path})
        assert metadata_file.status_code == 404

    def test_write_artwork_returns_error_for_invalid_artwork_path(self, api_client):
        """POST /write-artwork with a bad artwork path should return 404."""
        file_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac'
        img_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/gue.jpg'
        metadata_file = api_client.post("/write-artwork", json={"file_path": file_path, "artwork_path": img_path})
        assert metadata_file.status_code == 404

    def test_write_artwork_returns_error_for_invalid_image_format(self, api_client):
        """POST /write-artwork with a non-image file as artwork should return 422."""
        file_path = 'REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-01 I OWE IT TO YOU.flac'
        img_path = "REDACTED_USER_PATH/Documents/1 Projects/MT_UI/test_files/Maro - SO MUCH HAS CHANGED/MARO - SO MUCH HAS CHANGED - 01-03 KISS ME.flac"
        metadata_file = api_client.post("/write-artwork", json={"file_path": file_path, "artwork_path": img_path})
        assert metadata_file.status_code == 422
