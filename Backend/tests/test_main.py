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
        pass


class TestReadMetadataRoute:

    def test_read_returns_200_with_valid_file(self, api_client):
        """POST /read-metadata with a valid file path should return 200."""
        pass

    def test_read_returns_422_with_missing_body(self, api_client):
        """POST /read-metadata with no body should return 422."""
        pass

    def test_read_returns_error_for_invalid_path(self, api_client):
        """POST /read-metadata with a bad file path should return an error response."""
        pass


class TestWriteMetadataRoute:

    def test_write_returns_200_with_valid_payload(self, api_client):
        """POST /write-metadata with a full valid payload should return 200."""
        pass

    def test_write_returns_422_with_missing_fields(self, api_client):
        """POST /write-metadata with an incomplete payload should return 422."""
        pass

    def test_write_returns_error_for_invalid_path(self, api_client):
        """POST /write-metadata with a bad file path should return an error response."""
        pass
