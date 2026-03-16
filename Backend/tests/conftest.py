import pytest
from fastapi.testclient import TestClient
from main import app

# Shared fixtures available to all test files


@pytest.fixture
def spotify_client():
    """Return an instance of SpotifyClient for use in tests."""
    pass


@pytest.fixture
def sample_audio_file():
    """
    Provide a path to a small real audio_MT file used in metadata tests.
    Place a test file at tests/fixtures/sample.mp3
    """
    pass


@pytest.fixture
def api_client():
    """
    Return a TestClient wrapping the FastAPI app.
    Used for testing routes in test_main.py.
    """
    return TestClient(app)
